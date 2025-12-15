import * as vscode from 'vscode';
import * as cp from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

// Padrões para identificar elementos no código
const LUA_LOCAL_PATTERN = /local\s+(\w+)\s*=/g;
const LUA_FUNCTION_PATTERN = /(?:local\s+)?function\s+(\w+)\s*\(/g;
const LUA_FOR_PATTERN = /for\s+(\w+)\s*(?:,\s*(\w+))?\s*(?:=|in)/g;
const XML_TAG_PATTERN = /<(\w+(?:\.\w+)?)\s*[^>]*>/g;
const LUA_REQUIRE_PATTERN = /(?:local\s+)?(\w+)\s*=\s*require\s*\(\s*["']([^"']+)["']\s*\)/g;

type TagSource = 'document' | 'required-module' | 'workspace';

interface TagInfo {
    name: string;
    source: TagSource;
    detail?: string;
}

interface TagPropsInfo {
    props: Set<string>;
    source: string;
}

// Cache para indexação do workspace (tags e propTypes)
let workspaceTagsCache: Map<string, TagInfo> = new Map();
let workspacePropTypesCache: Map<string, TagPropsInfo> = new Map();
let workspaceIndexingPromise: Promise<void> | null = null;
let workspaceIndexLastUpdate: number = 0;
const WORKSPACE_INDEX_TTL = 30000; // 30s

// Cache para pacotes LuaRocks
let luarocksPackagesCache: Map<string, LuaRocksPackage> = new Map();
let luarocksLastUpdate: number = 0;
const LUAROCKS_CACHE_TTL = 60000; // 1 minuto

// Cache para módulos analisados
let moduleExportsCache: Map<string, ModuleExports> = new Map();

interface LuaRocksPackage {
    name: string;
    version: string;
    path?: string;
}

interface ModuleExports {
    functions: Map<string, { params?: string[]; description?: string }>;
    variables: Map<string, { type?: string }>;
    tags: Set<string>;
}

function getConfig<T>(key: string, defaultValue: T): T {
    return vscode.workspace.getConfiguration('daviluaxml').get<T>(key, defaultValue);
}

function decodeBufferToString(buffer: Uint8Array): string {
    return Buffer.from(buffer).toString('utf8');
}

function matchBalancedBraces(text: string, openBraceIndex: number): { start: number; end: number } | null {
    // Muito simples (não é um parser Lua completo). Faz o balanceamento de { } ignorando strings curtas.
    let i = openBraceIndex;
    if (text[i] !== '{') return null;

    let depth = 0;
    let inSingle = false;
    let inDouble = false;
    let inLongBracket = false;

    for (; i < text.length; i++) {
        const ch = text[i];
        const next = text[i + 1];

        if (!inSingle && !inDouble) {
            // long bracket [[ ... ]]
            if (!inLongBracket && ch === '[' && next === '[') {
                inLongBracket = true;
                i++;
                continue;
            }
            if (inLongBracket && ch === ']' && next === ']') {
                inLongBracket = false;
                i++;
                continue;
            }
        }

        if (inLongBracket) {
            continue;
        }

        // strings simples
        if (!inDouble && ch === "'" && text[i - 1] !== '\\') {
            inSingle = !inSingle;
            continue;
        }
        if (!inSingle && ch === '"' && text[i - 1] !== '\\') {
            inDouble = !inDouble;
            continue;
        }
        if (inSingle || inDouble) {
            continue;
        }

        if (ch === '{') depth++;
        if (ch === '}') {
            depth--;
            if (depth === 0) {
                return { start: openBraceIndex, end: i };
            }
        }
    }

    return null;
}

function extractLuaTableKeys(tableText: string): Set<string> {
    const keys = new Set<string>();

    // identificador =
    const identKey = /\b([A-Za-z_][\w_]*)\s*=/g;
    let m: RegExpExecArray | null;
    while ((m = identKey.exec(tableText)) !== null) {
        keys.add(m[1]);
    }

    // ["key"] =
    const bracketStringKey = /\[\s*["']([^"']+)["']\s*\]\s*=/g;
    while ((m = bracketStringKey.exec(tableText)) !== null) {
        keys.add(m[1]);
    }

    return keys;
}

function getTagNameAtPosition(linePrefix: string): { tagName: string | null; inTagName: boolean; inAttributes: boolean } {
    // Estamos dentro de um tag? (não passou de '>')
    const lastOpen = linePrefix.lastIndexOf('<');
    const lastClose = linePrefix.lastIndexOf('>');
    if (lastOpen === -1 || lastClose > lastOpen) {
        return { tagName: null, inTagName: false, inAttributes: false };
    }

    const afterOpen = linePrefix.slice(lastOpen + 1);
    // ignora fechamento </
    const clean = afterOpen.startsWith('/') ? afterOpen.slice(1) : afterOpen;
    const nameMatch = clean.match(/^([\w.]+)/);
    const tagName = nameMatch ? nameMatch[1] : null;

    if (!tagName) {
        return { tagName: null, inTagName: true, inAttributes: false };
    }

    const afterName = clean.slice(tagName.length);
    const inTagName = /^(?:\s*)$/.test(afterName);
    const inAttributes = /\s/.test(afterName);
    return { tagName, inTagName, inAttributes };
}

async function ensureWorkspaceIndex(): Promise<void> {
    const enableTagSuggestions = getConfig('enableTagSuggestions', true);
    if (!enableTagSuggestions) return;

    const now = Date.now();
    if (workspaceIndexingPromise) return workspaceIndexingPromise;
    if (now - workspaceIndexLastUpdate < WORKSPACE_INDEX_TTL && workspaceTagsCache.size > 0) return;

    workspaceIndexingPromise = (async () => {
        const tags = new Map<string, TagInfo>();
        const propTypes = new Map<string, TagPropsInfo>();

        const include = '**/*.{lua,dslx}';
        const exclude = '{**/node_modules/**,**/.git/**,**/lua_modules/**,**/.luarocks/**,**/dist/**,**/out/**}';
        const files = await vscode.workspace.findFiles(include, exclude, 2000);

        const proptypesRegisterPattern = /proptypes\s*\.\s*register\s*\(\s*["']([^"']+)["']\s*,\s*\{/g;
        const dotPropTypesPattern = /\b([A-Za-z_][\w_]*(?:\.[A-Za-z_][\w_]*)*)\s*\.\s*propTypes\s*=\s*\{/g;
        const componentFuncPattern = /(?:^|\n)\s*(?:local\s+)?function\s+([A-Za-z_][\w_]*(?:\.[A-Za-z_][\w_]*)*)\s*\([^)]*\)[\s\S]{0,2000}?\breturn\s*</g;
        const componentAssignPattern = /(?:^|\n)\s*(?:local\s+)?([A-Za-z_][\w_]*(?:\.[A-Za-z_][\w_]*)*)\s*=\s*function\s*\([^)]*\)[\s\S]{0,2000}?\breturn\s*</g;

        for (const uri of files) {
            try {
                const content = decodeBufferToString(await vscode.workspace.fs.readFile(uri));
                const rel = vscode.workspace.asRelativePath(uri);

                // Indexa componentes por heurística: função/assign que retorna tag
                let m: RegExpExecArray | null;
                while ((m = componentFuncPattern.exec(content)) !== null) {
                    const name = m[1];
                    if (!tags.has(name)) {
                        tags.set(name, { name, source: 'workspace', detail: `Found in ${rel}` });
                    }
                }
                componentAssignPattern.lastIndex = 0;
                while ((m = componentAssignPattern.exec(content)) !== null) {
                    const name = m[1];
                    if (!tags.has(name)) {
                        tags.set(name, { name, source: 'workspace', detail: `Found in ${rel}` });
                    }
                }

                // proptypes.register("Name", { ... })
                proptypesRegisterPattern.lastIndex = 0;
                while ((m = proptypesRegisterPattern.exec(content)) !== null) {
                    const compName = m[1];
                    const braceIndex = content.indexOf('{', m.index + m[0].lastIndexOf('{'));
                    const range = matchBalancedBraces(content, braceIndex);
                    if (!range) continue;

                    const tableText = content.slice(range.start, range.end + 1);
                    const keys = extractLuaTableKeys(tableText);
                    if (keys.size > 0) {
                        propTypes.set(compName, { props: keys, source: `proptypes.register in ${rel}` });
                    }
                }

                // Component.propTypes = { ... }
                dotPropTypesPattern.lastIndex = 0;
                while ((m = dotPropTypesPattern.exec(content)) !== null) {
                    const compName = m[1];
                    const braceIndex = content.indexOf('{', m.index + m[0].lastIndexOf('{'));
                    const range = matchBalancedBraces(content, braceIndex);
                    if (!range) continue;
                    const tableText = content.slice(range.start, range.end + 1);
                    const keys = extractLuaTableKeys(tableText);
                    if (keys.size > 0) {
                        propTypes.set(compName, { props: keys, source: `propTypes table in ${rel}` });
                    }
                }
            } catch {
                // Ignora arquivos com erro de leitura
            }
        }

        workspaceTagsCache = tags;
        workspacePropTypesCache = propTypes;
        workspaceIndexLastUpdate = Date.now();
    })().finally(() => {
        workspaceIndexingPromise = null;
    });

    return workspaceIndexingPromise;
}

// Tags XML comuns para sugestões
const COMMON_XML_TAGS = [
    { name: 'div', description: 'Container element' },
    { name: 'span', description: 'Inline container' },
    { name: 'p', description: 'Paragraph' },
    { name: 'h1', description: 'Heading level 1' },
    { name: 'h2', description: 'Heading level 2' },
    { name: 'h3', description: 'Heading level 3' },
    { name: 'ul', description: 'Unordered list' },
    { name: 'ol', description: 'Ordered list' },
    { name: 'li', description: 'List item' },
    { name: 'a', description: 'Anchor/link' },
    { name: 'img', description: 'Image' },
    { name: 'button', description: 'Button element' },
    { name: 'input', description: 'Input field' },
    { name: 'form', description: 'Form container' },
    { name: 'table', description: 'Table element' },
    { name: 'tr', description: 'Table row' },
    { name: 'td', description: 'Table cell' },
    { name: 'th', description: 'Table header cell' },
    { name: 'header', description: 'Header section' },
    { name: 'footer', description: 'Footer section' },
    { name: 'nav', description: 'Navigation section' },
    { name: 'section', description: 'Generic section' },
    { name: 'article', description: 'Article content' },
    { name: 'aside', description: 'Side content' },
    { name: 'main', description: 'Main content' },
];

// Funções Lua built-in
const LUA_BUILTINS = [
    { name: 'print', signature: 'print(...)', description: 'Prints values to stdout' },
    { name: 'pairs', signature: 'pairs(t)', description: 'Iterator for all key-value pairs' },
    { name: 'ipairs', signature: 'ipairs(t)', description: 'Iterator for array elements' },
    { name: 'type', signature: 'type(v)', description: 'Returns type of value' },
    { name: 'tostring', signature: 'tostring(v)', description: 'Converts to string' },
    { name: 'tonumber', signature: 'tonumber(v [, base])', description: 'Converts to number' },
    { name: 'require', signature: 'require(modname)', description: 'Loads a module' },
    { name: 'assert', signature: 'assert(v [, message])', description: 'Raises error if v is false' },
    { name: 'error', signature: 'error(message [, level])', description: 'Raises an error' },
    { name: 'pcall', signature: 'pcall(f, ...)', description: 'Protected call' },
    { name: 'xpcall', signature: 'xpcall(f, msgh, ...)', description: 'Protected call with handler' },
    { name: 'select', signature: 'select(index, ...)', description: 'Returns arguments after index' },
    { name: 'next', signature: 'next(table [, index])', description: 'Next key-value pair' },
    { name: 'rawget', signature: 'rawget(table, index)', description: 'Gets without metamethods' },
    { name: 'rawset', signature: 'rawset(table, index, value)', description: 'Sets without metamethods' },
    { name: 'setmetatable', signature: 'setmetatable(table, metatable)', description: 'Sets metatable' },
    { name: 'getmetatable', signature: 'getmetatable(object)', description: 'Gets metatable' },
];

// Bibliotecas Lua padrão
const LUA_LIBRARIES = [
    { name: 'string', methods: ['byte', 'char', 'find', 'format', 'gmatch', 'gsub', 'len', 'lower', 'match', 'rep', 'reverse', 'sub', 'upper'] },
    { name: 'table', methods: ['concat', 'insert', 'move', 'pack', 'remove', 'sort', 'unpack'] },
    { name: 'math', methods: ['abs', 'acos', 'asin', 'atan', 'ceil', 'cos', 'deg', 'exp', 'floor', 'fmod', 'huge', 'log', 'max', 'min', 'modf', 'pi', 'rad', 'random', 'randomseed', 'sin', 'sqrt', 'tan', 'tointeger', 'type', 'ult'] },
    { name: 'io', methods: ['close', 'flush', 'input', 'lines', 'open', 'output', 'popen', 'read', 'tmpfile', 'type', 'write'] },
    { name: 'os', methods: ['clock', 'date', 'difftime', 'execute', 'exit', 'getenv', 'remove', 'rename', 'setlocale', 'time', 'tmpname'] },
];

interface DocumentSymbols {
    variables: Map<string, { line: number; type?: string }>;
    functions: Map<string, { line: number; params?: string[] }>;
    tags: Set<string>;
    requires: Map<string, string>;
}

// Buscar pacotes LuaRocks instalados
async function getLuaRocksPackages(): Promise<Map<string, LuaRocksPackage>> {
    const now = Date.now();
    if (now - luarocksLastUpdate < LUAROCKS_CACHE_TTL && luarocksPackagesCache.size > 0) {
        return luarocksPackagesCache;
    }

    return new Promise((resolve) => {
        cp.exec('luarocks list --porcelain', (error, stdout, stderr) => {
            if (error) {
                console.log('LuaRocks not available or error:', error.message);
                resolve(luarocksPackagesCache);
                return;
            }

            const packages = new Map<string, LuaRocksPackage>();
            const lines = stdout.split('\n');
            
            for (const line of lines) {
                const parts = line.trim().split('\t');
                if (parts.length >= 2) {
                    const name = parts[0];
                    const version = parts[1];
                    packages.set(name, { name, version });
                }
            }

            luarocksPackagesCache = packages;
            luarocksLastUpdate = now;
            resolve(packages);
        });
    });
}

// Encontrar o caminho de um módulo Lua
function findModulePath(moduleName: string, workspaceRoot: string): string | null {
    // Converter nome do módulo para caminho
    const moduleFile = moduleName.replace(/\./g, '/');
    
    // Locais para procurar
    const searchPaths = [
        path.join(workspaceRoot, moduleFile + '.lua'),
        path.join(workspaceRoot, moduleFile + '.dslx'),
        path.join(workspaceRoot, moduleFile, 'init.lua'),
        path.join(workspaceRoot, moduleFile, 'init.dslx'),
        path.join(workspaceRoot, 'lua_modules', 'share', 'lua', '5.4', moduleFile + '.lua'),
        path.join(workspaceRoot, 'lua_modules', 'share', 'lua', '5.4', moduleFile, 'init.lua'),
    ];

    // Adicionar LUA_PATH do sistema
    const luaPath = process.env.LUA_PATH || '';
    const pathPatterns = luaPath.split(';');
    for (const pattern of pathPatterns) {
        if (pattern && pattern !== ';;') {
            const filePath = pattern.replace('?', moduleFile).replace('?.lua', moduleFile + '.lua');
            if (!filePath.includes('?')) {
                searchPaths.push(filePath);
            }
        }
    }

    for (const searchPath of searchPaths) {
        try {
            if (fs.existsSync(searchPath)) {
                return searchPath;
            }
        } catch {
            // Ignorar erros de acesso
        }
    }

    return null;
}

// Analisar exports de um módulo Lua
function analyzeModuleExports(filePath: string): ModuleExports {
    if (moduleExportsCache.has(filePath)) {
        return moduleExportsCache.get(filePath)!;
    }

    const exports: ModuleExports = {
        functions: new Map(),
        variables: new Map(),
        tags: new Set(),
    };

    try {
        const content = fs.readFileSync(filePath, 'utf-8');

        // Encontrar funções exportadas (M.funcName = function ou function M.funcName)
        const moduleTablePattern = /(\w+)\.(\w+)\s*=\s*function\s*\(([^)]*)\)/g;
        let match;
        while ((match = moduleTablePattern.exec(content)) !== null) {
            const funcName = match[2];
            const params = match[3].split(',').map(p => p.trim()).filter(p => p);
            exports.functions.set(funcName, { params });
        }

        // Encontrar funções em return { ... }
        const returnTableMatch = content.match(/return\s*\{([^}]+)\}/s);
        if (returnTableMatch) {
            const tableContent = returnTableMatch[1];
            // Funções inline: funcName = function(...)
            const inlineFuncPattern = /(\w+)\s*=\s*function\s*\(([^)]*)\)/g;
            while ((match = inlineFuncPattern.exec(tableContent)) !== null) {
                const funcName = match[1];
                const params = match[2].split(',').map(p => p.trim()).filter(p => p);
                exports.functions.set(funcName, { params });
            }
            // Referências a funções locais: funcName = localFunc ou apenas funcName
            const refPattern = /(\w+)\s*(?:=\s*(\w+))?\s*[,}]/g;
            while ((match = refPattern.exec(tableContent)) !== null) {
                const exportName = match[1];
                if (!exports.functions.has(exportName) && !['function', 'end', 'local', 'return'].includes(exportName)) {
                    exports.variables.set(exportName, {});
                }
            }
        }

        // Encontrar tags XML usadas no módulo
        const xmlTagPattern = /<(\w+(?:\.\w+)?)\s*[^>]*>/g;
        while ((match = xmlTagPattern.exec(content)) !== null) {
            exports.tags.add(match[1]);
        }

        // Procurar por componentes (funções que retornam tags)
        const componentPattern = /(?:local\s+)?function\s+(\w+)\s*\([^)]*\)[^]*?return\s+</g;
        while ((match = componentPattern.exec(content)) !== null) {
            const funcName = match[1];
            if (!exports.functions.has(funcName)) {
                exports.functions.set(funcName, { params: [], description: 'Component' });
            }
        }

        moduleExportsCache.set(filePath, exports);
    } catch (error) {
        console.log('Error analyzing module:', error);
    }

    return exports;
}

function analyzeDocument(document: vscode.TextDocument): DocumentSymbols {
    const text = document.getText();
    const symbols: DocumentSymbols = {
        variables: new Map(),
        functions: new Map(),
        tags: new Set(),
        requires: new Map(),
    };

    // Encontrar variáveis locais
    let match;
    while ((match = LUA_LOCAL_PATTERN.exec(text)) !== null) {
        const name = match[1];
        const line = document.positionAt(match.index).line;
        symbols.variables.set(name, { line });
    }

    // Encontrar funções
    LUA_FUNCTION_PATTERN.lastIndex = 0;
    while ((match = LUA_FUNCTION_PATTERN.exec(text)) !== null) {
        const name = match[1];
        const line = document.positionAt(match.index).line;
        // Tentar extrair parâmetros
        const afterMatch = text.slice(match.index + match[0].length);
        const paramsMatch = afterMatch.match(/^([^)]*)\)/);
        const params = paramsMatch ? paramsMatch[1].split(',').map(p => p.trim()).filter(p => p) : [];
        symbols.functions.set(name, { line, params });
    }

    // Encontrar variáveis de for
    LUA_FOR_PATTERN.lastIndex = 0;
    while ((match = LUA_FOR_PATTERN.exec(text)) !== null) {
        const line = document.positionAt(match.index).line;
        if (match[1]) {
            symbols.variables.set(match[1], { line });
        }
        if (match[2]) {
            symbols.variables.set(match[2], { line });
        }
    }

    // Encontrar tags XML usadas
    XML_TAG_PATTERN.lastIndex = 0;
    while ((match = XML_TAG_PATTERN.exec(text)) !== null) {
        symbols.tags.add(match[1]);
    }

    // Encontrar requires
    LUA_REQUIRE_PATTERN.lastIndex = 0;
    while ((match = LUA_REQUIRE_PATTERN.exec(text)) !== null) {
        symbols.requires.set(match[1], match[2]);
    }

    return symbols;
}

class LuaXMLCompletionProvider implements vscode.CompletionItemProvider {
    async provideCompletionItems(
        document: vscode.TextDocument,
        position: vscode.Position,
        token: vscode.CancellationToken,
        context: vscode.CompletionContext
    ): Promise<vscode.CompletionItem[] | vscode.CompletionList> {
        const lineText = document.lineAt(position).text;
        const linePrefix = lineText.substring(0, position.character);
        const items: vscode.CompletionItem[] = [];

        const symbols = analyzeDocument(document);
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || '';

        const enableTagSuggestions = getConfig('enableTagSuggestions', true);
        const enableVariableSuggestions = getConfig('enableVariableSuggestions', true);

        if (enableTagSuggestions) {
            await ensureWorkspaceIndex();
        }

        // Detectar se estamos dentro de require("")
        const inRequire = /require\s*\(\s*["'][^"']*$/.test(linePrefix);

        // Detectar se estamos dentro de uma tag XML (após <)
        const inXmlTag = /<[\w.]*$/.test(linePrefix) || getTagNameAtPosition(linePrefix).tagName !== null;
        
        // Detectar se estamos após um ponto (acesso a método/propriedade)
        const dotMatch = linePrefix.match(/(\w+)\.\w*$/);

        if (inRequire) {
            // Sugerir pacotes LuaRocks instalados
            const packages = await getLuaRocksPackages();
            for (const [name, pkg] of packages) {
                const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Module);
                item.detail = `LuaRocks: ${pkg.version}`;
                item.insertText = name;
                items.push(item);
            }

            // Sugerir módulos do workspace
            if (workspaceRoot) {
                const luaFiles = await this.findLuaFilesInWorkspace(workspaceRoot);
                for (const file of luaFiles) {
                    const relativePath = path.relative(workspaceRoot, file);
                    const moduleName = relativePath
                        .replace(/\.(lua|dslx)$/, '')
                        .replace(/\/init$/, '')
                        .replace(/\//g, '.');
                    
                    const item = new vscode.CompletionItem(moduleName, vscode.CompletionItemKind.File);
                    item.detail = `Local: ${relativePath}`;
                    item.insertText = moduleName;
                    items.push(item);
                }
            }
        } else if (inXmlTag) {
            const tagCtx = getTagNameAtPosition(linePrefix);

            // Se já temos nome do tag e estamos nos atributos, sugerir props/atributos
            if (enableTagSuggestions && tagCtx.tagName && tagCtx.inAttributes) {
                const exact = workspacePropTypesCache.get(tagCtx.tagName);
                const fallback = tagCtx.tagName.includes('.') ? workspacePropTypesCache.get(tagCtx.tagName.split('.').pop()!) : undefined;
                const propsInfo = exact || fallback;

                if (propsInfo) {
                    for (const propName of propsInfo.props) {
                        const item = new vscode.CompletionItem(propName, vscode.CompletionItemKind.Property);
                        item.detail = `propTypes (${propsInfo.source})`;
                        item.insertText = new vscode.SnippetString(`${propName}="$1"`);
                        item.sortText = '0' + propName;
                        items.push(item);
                    }
                }
            }

            // Sugerir tags XML
            // Tags usadas no documento
            for (const tag of symbols.tags) {
                const item = new vscode.CompletionItem(tag, vscode.CompletionItemKind.Class);
                item.detail = 'Tag used in this document';
                item.insertText = new vscode.SnippetString(`${tag} $1>$2</${tag}>`);
                item.sortText = '0' + tag;
                items.push(item);
            }

            // Funções como tags (componentes)
            for (const [name, info] of symbols.functions) {
                const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Function);
                item.detail = 'Component function';
                item.insertText = new vscode.SnippetString(`${name} $1>$2</${name}>`);
                item.sortText = '1' + name;
                items.push(item);
            }

            // Tags/componentes do workspace (mesmo sem require explícito)
            if (enableTagSuggestions) {
                for (const [name, info] of workspaceTagsCache) {
                    // evita duplicar o que já está no documento
                    if (symbols.functions.has(name) || symbols.tags.has(name)) continue;
                    const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Function);
                    item.detail = info.detail || 'Workspace component';
                    item.insertText = new vscode.SnippetString(`${name} $1>$2</${name}>`);
                    item.sortText = '2' + name;
                    items.push(item);
                }
            }

            // Tags de módulos importados
            for (const [varName, moduleName] of symbols.requires) {
                const modulePath = findModulePath(moduleName, workspaceRoot);
                if (modulePath) {
                    const moduleExports = analyzeModuleExports(modulePath);
                    
                    // Adicionar tags do módulo
                    for (const tag of moduleExports.tags) {
                        const item = new vscode.CompletionItem(tag, vscode.CompletionItemKind.Class);
                        item.detail = `Tag from ${moduleName}`;
                        item.insertText = new vscode.SnippetString(`${tag} $1>$2</${tag}>`);
                        item.sortText = '1' + tag;
                        items.push(item);
                    }

                    // Adicionar componentes do módulo como tags (varName.Component)
                    for (const [funcName, funcInfo] of moduleExports.functions) {
                        const fullName = `${varName}.${funcName}`;
                        const item = new vscode.CompletionItem(fullName, vscode.CompletionItemKind.Function);
                        item.detail = funcInfo.description || `Component from ${moduleName}`;
                        item.insertText = new vscode.SnippetString(`${fullName} $1>$2</${fullName}>`);
                        item.sortText = '2' + fullName;
                        items.push(item);
                    }
                }
            }

            // Tags comuns
            for (const tag of COMMON_XML_TAGS) {
                if (!symbols.tags.has(tag.name)) {
                    const item = new vscode.CompletionItem(tag.name, vscode.CompletionItemKind.Keyword);
                    item.detail = tag.description;
                    item.insertText = new vscode.SnippetString(`${tag.name} $1>$2</${tag.name}>`);
                    item.sortText = '3' + tag.name;
                    items.push(item);
                }
            }
        } else if (dotMatch) {
            // Sugerir métodos/propriedades após ponto
            const objectName = dotMatch[1];
            
            // Verificar se é uma biblioteca Lua padrão
            const lib = LUA_LIBRARIES.find(l => l.name === objectName);
            if (lib) {
                for (const method of lib.methods) {
                    const item = new vscode.CompletionItem(method, vscode.CompletionItemKind.Method);
                    item.detail = `${objectName}.${method}`;
                    items.push(item);
                }
            }

            // Verificar se é um módulo importado
            if (symbols.requires.has(objectName)) {
                const moduleName = symbols.requires.get(objectName)!;
                const modulePath = findModulePath(moduleName, workspaceRoot);
                
                if (modulePath) {
                    const moduleExports = analyzeModuleExports(modulePath);
                    
                    // Adicionar funções exportadas
                    for (const [funcName, funcInfo] of moduleExports.functions) {
                        const item = new vscode.CompletionItem(funcName, vscode.CompletionItemKind.Function);
                        const params = funcInfo.params?.join(', ') || '';
                        item.detail = `${objectName}.${funcName}(${params})`;
                        item.insertText = new vscode.SnippetString(`${funcName}($1)`);
                        items.push(item);
                    }

                    // Adicionar variáveis exportadas
                    for (const [varName, varInfo] of moduleExports.variables) {
                        const item = new vscode.CompletionItem(varName, vscode.CompletionItemKind.Variable);
                        item.detail = `${objectName}.${varName}`;
                        items.push(item);
                    }
                }
            }
        } else {
            // Contexto Lua normal - sugerir variáveis, funções, builtins

            if (enableVariableSuggestions) {
                // Variáveis do documento
                for (const [name, info] of symbols.variables) {
                    const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Variable);
                    item.detail = `Local variable (line ${info.line + 1})`;
                    item.sortText = '0' + name;
                    items.push(item);
                }
            }

            // Funções do documento
            for (const [name, info] of symbols.functions) {
                const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Function);
                const params = info.params?.join(', ') || '';
                item.detail = `function ${name}(${params})`;
                item.insertText = new vscode.SnippetString(`${name}($1)`);
                item.sortText = '1' + name;
                items.push(item);
            }

            // Requires do documento
            for (const [name, moduleName] of symbols.requires) {
                const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Module);
                item.detail = `require("${moduleName}")`;
                item.sortText = '2' + name;
                items.push(item);
            }

            // Builtins Lua
            for (const builtin of LUA_BUILTINS) {
                const item = new vscode.CompletionItem(builtin.name, vscode.CompletionItemKind.Function);
                item.detail = builtin.signature;
                item.documentation = builtin.description;
                item.insertText = new vscode.SnippetString(`${builtin.name}($1)`);
                item.sortText = '3' + builtin.name;
                items.push(item);
            }

            // Bibliotecas Lua
            for (const lib of LUA_LIBRARIES) {
                const item = new vscode.CompletionItem(lib.name, vscode.CompletionItemKind.Module);
                item.detail = `Lua ${lib.name} library`;
                item.sortText = '4' + lib.name;
                items.push(item);
            }

            // Pacotes LuaRocks (para acesso direto, não dentro de require)
            const packages = await getLuaRocksPackages();
            for (const [name, pkg] of packages) {
                const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Module);
                item.detail = `LuaRocks package: ${pkg.version}`;
                item.sortText = '5' + name;
                items.push(item);
            }

            // Keywords Lua
            const keywords = ['local', 'function', 'end', 'if', 'then', 'else', 'elseif', 'for', 'while', 'do', 'repeat', 'until', 'return', 'break', 'in', 'and', 'or', 'not', 'true', 'false', 'nil'];
            for (const kw of keywords) {
                const item = new vscode.CompletionItem(kw, vscode.CompletionItemKind.Keyword);
                item.sortText = '6' + kw;
                items.push(item);
            }
        }

        return items;
    }

    private async findLuaFilesInWorkspace(workspaceRoot: string): Promise<string[]> {
        const files: string[] = [];
        
        async function scanDir(dir: string, depth: number = 0) {
            if (depth > 5) return; // Limitar profundidade
            
            try {
                const entries = fs.readdirSync(dir, { withFileTypes: true });
                for (const entry of entries) {
                    const fullPath = path.join(dir, entry.name);
                    
                    if (entry.isDirectory()) {
                        // Ignorar diretórios comuns
                        if (!['node_modules', '.git', 'lua_modules', '.luarocks'].includes(entry.name)) {
                            await scanDir(fullPath, depth + 1);
                        }
                    } else if (entry.isFile() && (entry.name.endsWith('.lua') || entry.name.endsWith('.dslx'))) {
                        files.push(fullPath);
                    }
                }
            } catch {
                // Ignorar erros de acesso
            }
        }

        await scanDir(workspaceRoot);
        return files;
    }
}

class LuaXMLHoverProvider implements vscode.HoverProvider {
    provideHover(
        document: vscode.TextDocument,
        position: vscode.Position,
        token: vscode.CancellationToken
    ): vscode.ProviderResult<vscode.Hover> {
        const wordRange = document.getWordRangeAtPosition(position);
        if (!wordRange) {
            return null;
        }

        const word = document.getText(wordRange);
        const symbols = analyzeDocument(document);
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || '';

        // Verificar se é uma variável local
        if (symbols.variables.has(word)) {
            const info = symbols.variables.get(word)!;
            return new vscode.Hover(
                new vscode.MarkdownString(`**Local variable** \`${word}\`\n\nDefined at line ${info.line + 1}`)
            );
        }

        // Verificar se é uma função local
        if (symbols.functions.has(word)) {
            const info = symbols.functions.get(word)!;
            const params = info.params?.join(', ') || '';
            return new vscode.Hover(
                new vscode.MarkdownString(`**Function** \`${word}(${params})\`\n\nDefined at line ${info.line + 1}`)
            );
        }

        // Verificar se é um módulo importado
        if (symbols.requires.has(word)) {
            const moduleName = symbols.requires.get(word)!;
            const modulePath = findModulePath(moduleName, workspaceRoot);
            
            let content = `**Module** \`${moduleName}\``;
            
            if (modulePath) {
                const moduleExports = analyzeModuleExports(modulePath);
                const funcs = Array.from(moduleExports.functions.keys());
                const vars = Array.from(moduleExports.variables.keys());
                
                if (funcs.length > 0) {
                    content += `\n\n**Functions:** ${funcs.join(', ')}`;
                }
                if (vars.length > 0) {
                    content += `\n\n**Variables:** ${vars.join(', ')}`;
                }
            }
            
            return new vscode.Hover(new vscode.MarkdownString(content));
        }

        // Verificar se é um builtin
        const builtin = LUA_BUILTINS.find(b => b.name === word);
        if (builtin) {
            return new vscode.Hover(
                new vscode.MarkdownString(`**Lua Built-in**\n\n\`${builtin.signature}\`\n\n${builtin.description}`)
            );
        }

        // Verificar se é uma biblioteca
        const lib = LUA_LIBRARIES.find(l => l.name === word);
        if (lib) {
            return new vscode.Hover(
                new vscode.MarkdownString(`**Lua Library** \`${word}\`\n\nMethods: ${lib.methods.join(', ')}`)
            );
        }

        // Verificar se é uma tag XML comum
        const tag = COMMON_XML_TAGS.find(t => t.name === word);
        if (tag) {
            return new vscode.Hover(
                new vscode.MarkdownString(`**XML Tag** \`<${word}>\`\n\n${tag.description}`)
            );
        }

        // Verificar se é uma tag usada no documento
        if (symbols.tags.has(word)) {
            return new vscode.Hover(
                new vscode.MarkdownString(`**XML Tag** \`<${word}>\`\n\nUsed in this document`)
            );
        }

        return null;
    }
}

class LuaXMLSignatureHelpProvider implements vscode.SignatureHelpProvider {
    provideSignatureHelp(
        document: vscode.TextDocument,
        position: vscode.Position,
        token: vscode.CancellationToken,
        context: vscode.SignatureHelpContext
    ): vscode.ProviderResult<vscode.SignatureHelp> {
        const lineText = document.lineAt(position).text;
        const linePrefix = lineText.substring(0, position.character);

        // Encontrar a função sendo chamada (incluindo módulo.função)
        const funcMatch = linePrefix.match(/(?:(\w+)\.)?(\w+)\s*\([^)]*$/);
        if (!funcMatch) {
            return null;
        }

        const moduleName = funcMatch[1];
        const funcName = funcMatch[2];
        const symbols = analyzeDocument(document);
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || '';

        // Verificar se é uma função de módulo importado
        if (moduleName && symbols.requires.has(moduleName)) {
            const requirePath = symbols.requires.get(moduleName)!;
            const modulePath = findModulePath(requirePath, workspaceRoot);
            
            if (modulePath) {
                const moduleExports = analyzeModuleExports(modulePath);
                
                if (moduleExports.functions.has(funcName)) {
                    const info = moduleExports.functions.get(funcName)!;
                    const params = info.params || [];
                    
                    const signature = new vscode.SignatureInformation(
                        `${moduleName}.${funcName}(${params.join(', ')})`,
                        info.description || `Function from ${requirePath}`
                    );
                    
                    for (const param of params) {
                        signature.parameters.push(new vscode.ParameterInformation(param));
                    }

                    const help = new vscode.SignatureHelp();
                    help.signatures = [signature];
                    help.activeSignature = 0;
                    
                    const afterFunc = linePrefix.slice(linePrefix.lastIndexOf('(') + 1);
                    const commas = (afterFunc.match(/,/g) || []).length;
                    help.activeParameter = Math.min(commas, params.length - 1);

                    return help;
                }
            }
        }

        // Verificar se é uma função local
        if (!moduleName && symbols.functions.has(funcName)) {
            const info = symbols.functions.get(funcName)!;
            const params = info.params || [];
            
            const signature = new vscode.SignatureInformation(
                `${funcName}(${params.join(', ')})`,
                `Local function defined at line ${info.line + 1}`
            );
            
            for (const param of params) {
                signature.parameters.push(new vscode.ParameterInformation(param));
            }

            const help = new vscode.SignatureHelp();
            help.signatures = [signature];
            help.activeSignature = 0;
            
            const afterFunc = linePrefix.slice(linePrefix.lastIndexOf('(') + 1);
            const commas = (afterFunc.match(/,/g) || []).length;
            help.activeParameter = Math.min(commas, params.length - 1);

            return help;
        }

        // Verificar se é um builtin
        const builtin = LUA_BUILTINS.find(b => b.name === funcName);
        if (builtin && !moduleName) {
            const signature = new vscode.SignatureInformation(
                builtin.signature,
                builtin.description
            );

            const paramsMatch = builtin.signature.match(/\(([^)]*)\)/);
            if (paramsMatch) {
                const params = paramsMatch[1].split(',').map(p => p.trim()).filter(p => p);
                for (const param of params) {
                    signature.parameters.push(new vscode.ParameterInformation(param));
                }
            }

            const help = new vscode.SignatureHelp();
            help.signatures = [signature];
            help.activeSignature = 0;

            const afterFunc = linePrefix.slice(linePrefix.lastIndexOf('(') + 1);
            const commas = (afterFunc.match(/,/g) || []).length;
            help.activeParameter = commas;

            return help;
        }

        return null;
    }
}

export function activate(context: vscode.ExtensionContext) {
    console.log('LuaXML extension is now active!');

    // Atualiza index do workspace no background
    ensureWorkspaceIndex();

    const watcher = vscode.workspace.createFileSystemWatcher('**/*.{lua,dslx}');
    const invalidateWorkspaceIndex = () => {
        workspaceIndexLastUpdate = 0;
        // Não limpa as caches imediatamente (evita flicker); só força rebuild na próxima sugestão.
    };
    watcher.onDidCreate(invalidateWorkspaceIndex);
    watcher.onDidChange(invalidateWorkspaceIndex);
    watcher.onDidDelete(invalidateWorkspaceIndex);
    context.subscriptions.push(watcher);

    // Registrar providers
    const completionProvider = vscode.languages.registerCompletionItemProvider(
        { language: 'luaxml', scheme: 'file' },
        new LuaXMLCompletionProvider(),
        '<', ' ', '.', ':', '"', "'", '='
    );

    const hoverProvider = vscode.languages.registerHoverProvider(
        { language: 'luaxml', scheme: 'file' },
        new LuaXMLHoverProvider()
    );

    const signatureProvider = vscode.languages.registerSignatureHelpProvider(
        { language: 'luaxml', scheme: 'file' },
        new LuaXMLSignatureHelpProvider(),
        '(', ','
    );

    context.subscriptions.push(completionProvider, hoverProvider, signatureProvider);

    // Comando para recarregar cache
    const reloadCacheCommand = vscode.commands.registerCommand('luaxml.reloadCache', () => {
        luarocksPackagesCache.clear();
        luarocksLastUpdate = 0;
        moduleExportsCache.clear();
        vscode.window.showInformationMessage('LuaXML: Cache cleared and will reload on next completion');
    });

    // Comando para informações
    const infoCommand = vscode.commands.registerCommand('luaxml.showInfo', () => {
        vscode.window.showInformationMessage('LuaXML: Lua with XML syntax support. Use <tag> elements in your Lua code!');
    });

    context.subscriptions.push(reloadCacheCommand, infoCommand);
}

export function deactivate() {
    console.log('LuaXML extension deactivated');
}
