--[[
    DaviLuaXML Help
    ===========
    
    Modulo de ajuda que fornece documentacao sobre o uso do DaviLuaXML.
    Suporta multiplos idiomas: en (English), pt (Portugues), es (Espanol).
    
    USO:
    ----
    local help = require("DaviLuaXML.help")
    help()           -- Exibe ajuda geral
    help("parser")   -- Exibe ajuda do modulo parser
    help.list()      -- Lista todos os topicos disponiveis
    help.lang("pt")  -- Define o idioma (en, pt, es)
]]

local help = {}

--------------------------------------------------------------------------------
-- CONFIGURACAO DE IDIOMA
--------------------------------------------------------------------------------

help.currentLang = "en"

--- Define o idioma da ajuda.
--- @param lang string Codigo do idioma: "en", "pt", "es"
function help.lang(lang)
    if lang == "en" or lang == "pt" or lang == "es" then
        help.currentLang = lang
        return true
    end
    return false, "Invalid language. Use: en, pt, es"
end

--------------------------------------------------------------------------------
-- TEXTOS DE AJUDA - ENGLISH
--------------------------------------------------------------------------------

help.en = {}

help.en.general = [=[
======================================================================
                          DaviLuaXML - Help                              
======================================================================

DaviLuaXML is a library that allows using XML syntax inside Lua code.
XML tags are transformed into Lua function calls.

QUICK START:
------------
    -- 1. Load DaviLuaXML at the beginning of your program
    require("DaviLuaXML")
    
    -- 2. Now you can use require() with .dslx files
    local App = require("my_component")  -- loads my_component.dslx

BASIC EXAMPLE:
--------------
    -- file: app.dslx
    local function Button(props, children)
        return string.format('<button class="%s">%s</button>', 
            props.class or "", 
            children[1] or "")
    end
    
    local html = <Button class="primary">Click here</Button>
    print(html)  -- <button class="primary">Click here</button>

AVAILABLE TOPICS:
-----------------
Use help("topic") for more information:
    - general    - This page
    - syntax     - Supported XML syntax
    - parser     - Parsing module
    - transform  - Transformation module
    - runtime    - Runtime helper (invoke wrapper)
    - proptypes  - Props validation (PropTypes)
    - sourcemap  - Error line mapping for .dslx
    - treeshake  - Tree-shaking (compiler)
    - compile    - Pre-compile .dslx -> .lua
    - elements   - Element creation
    - props      - Property handling
    - middleware - Middleware system for props/children
    - errors     - Error system
    - core       - File loading
    - init       - Require system

LANGUAGE:
---------
Use help.lang("code") to change language:
    - en - English
    - pt - Portugues
    - es - Espanol

Type: require("DaviLuaXML.help").list() to list all topics.
]=]

help.en.syntax = [=[
======================================================================
                       DaviLuaXML - XML Syntax                           
======================================================================

BASIC TAGS:
-----------
    -- Self-closing tag (no content)
    <MyTag/>
    
    -- Tag with content
    <MyTag>content here</MyTag>
    
    -- Nested tags
    <Parent>
        <Child>text</Child>
    </Parent>

ATTRIBUTES:
-----------
    -- Strings
    <Tag name="value"/>
    
    -- Without quotes (simple values)
    <Tag active=true count=5/>
    
    -- Lua expressions in braces
    <Tag value={10 + 5} list={myTable}/>

EXPRESSIONS IN CONTENT:
-----------------------
    -- Lua expressions inside tags
    <Tag>{variable}</Tag>
    <Tag>{1 + 2 + 3}</Tag>
    <Tag>{"string"}</Tag>
    
    -- Multiple expressions
    <List>{item1}{item2}{item3}</List>

NAMES WITH DOT:
---------------
    -- Access to modules/namespaces
    <html.div class="container"/>
    <ui.Button onClick={handler}/>

TRANSFORMATION:
---------------
    -- XML code is transformed into calls routed through a runtime helper:
    <Tag prop="value">text</Tag>
    
    -- Becomes:
    __daviluaxml_invoke(Tag, 'Tag', {prop = 'value'}, {[1] = 'text'})
    
    -- The function receives: (props, children)
]=]

help.en.parser = [=[
======================================================================
                         DaviLuaXML - Parser                              
======================================================================

The parser module converts XML strings into Lua tables.

USAGE:
------
    local parser = require("DaviLuaXML.parser")
    local node, startPos, endPos = parser(code)

PARAMETERS:
-----------
    code (string)    - Code containing an XML tag

RETURN:
-------
    node (table)     - Table representing the element:
                       { tag = string, props = table, children = array }
    startPos (number)- Start position of the tag in the code
    endPos (number)  - End position of the tag in the code

EXAMPLE:
--------
    local parser = require("DaviLuaXML.parser")
    
    local node = parser('<div class="container"><span>text</span></div>')
    
    print(node.tag)              -- "div"
    print(node.props.class)      -- "container"
    print(node.children[1].tag)  -- "span"
    print(node.children[1].children[1])  -- "text"

NODE STRUCTURE:
---------------
    {
        tag = "div",
        props = {
            class = "container"
        },
        children = {
            [1] = {
                tag = "span",
                props = {},
                children = { "text" }
            }
        }
    }
]=]

help.en.transform = [==[
======================================================================
                        DaviLuaXML - Transform                            
======================================================================

The transform module converts Lua+XML code into pure Lua code.

USAGE:
------
    local transform = require("DaviLuaXML.transform").transform
    local result, err, map = transform(code, file)

PARAMETERS:
-----------
    code (string)    - Lua code containing XML tags
    file (string)    - File name (optional, for error messages)

RETURN:
-------
    result (string)  - Transformed Lua code (or nil if error)
    err (string)     - Error message (or nil if success)
    map (table)       - Optional sourcemap info (line mapping)

EXAMPLE:
--------
    local transform = require("DaviLuaXML.transform").transform
    
    local code = [[
        local function Comp(props)
            return props.x * 2
        end
        local result = <Comp x={21}/>
    ]]
    
    local pure_lua = transform(code)
    print(pure_lua)

NOTES:
------
    - Lua reserved tags (const, close) are preserved
    - Multiple tags can exist in the same code
    - Expressions in {} are evaluated during transformation
    - When at least one tag is transformed, a helper binding is injected:
        local __daviluaxml_invoke = require("DaviLuaXML.runtime").invoke
]==]

help.en.runtime = [=[
======================================================================
                         DaviLuaXML - Runtime
======================================================================

The runtime module provides helpers used by transformed code.

The transformer routes tag calls through:
    __daviluaxml_invoke(tagExpr, 'tagName', props, children)

This enables features like:
  - prop validation (PropTypes)
  - consistent invocation of functions / callable tables

USAGE:
------
    local runtime = require("DaviLuaXML.runtime")
    local result = runtime.invoke(MyTag, "MyTag", {x = 1}, {"child"})

CALLABLE RULES:
--------------
runtime.invoke supports:
  - function(props, children)
  - callable table via metatable __call
  - table with render(props, children)
]=]

help.en.proptypes = [=[
======================================================================
                        DaviLuaXML - PropTypes
======================================================================

PropTypes is an optional runtime props validation system.

You can define schemas in two ways:

1) Registry (by tag name):
    local t = require("DaviLuaXML.proptypes")
    t.register("Button", {
        label = t.string({ required = true }),
        disabled = t.boolean(),
        variant = t.oneOf({"primary", "secondary"}),
    })

2) Component-local (propTypes field):
    local t = require("DaviLuaXML.proptypes")
    local Button = setmetatable({
        propTypes = { label = t.string({ required = true }) }
    }, { __call = function(self, props, children) ... end })

Disable validation:
    require("DaviLuaXML.proptypes").enabled = false
]=]

help.en.sourcemap = [=[
======================================================================
                        DaviLuaXML - Sourcemaps
======================================================================

DaviLuaXML generates a simple line-based mapping when transforming .dslx.

The loader (require searcher) and core runner rewrite runtime errors so
line numbers point to the original .dslx file.

LIMITATIONS:
------------
This is a lightweight line mapper (not a full column-accurate sourcemap).
]=]

help.en.treeshake = [=[
======================================================================
                       DaviLuaXML - Tree-shaking
======================================================================

Tree-shaking is a conservative compiler-only pass.

It comments out unused lines like:
    local X = require("...")

If the identifier X is not referenced elsewhere, the line is commented.

USAGE (CLI):
-----------
    dslxc --treeshake src/ dist/
]=]

help.en.compile = [=[
======================================================================
                         DaviLuaXML - Compile
======================================================================

The compile module pre-compiles .dslx files into plain .lua.

USAGE:
------
    local compile = require("DaviLuaXML.compile")
    compile.file("app.dslx")
    compile.dir("src/", "dist/")

CLI:
----
    dslxc app.dslx
    dslxc src/ dist/

OPTIONS:
--------
    --no-header   Do not add header
    --treeshake   Comment-out unused requires
]=]

help.en.elements = [=[
======================================================================
                        DaviLuaXML - Elements                             
======================================================================

The elements module provides functions to create elements programmatically.

USAGE:
------
    local elements = require("DaviLuaXML.elements")
    local el = elements:createElement(tag, props, children)

PARAMETERS:
-----------
    tag (string)      - Tag name
    props (table)     - Properties table (can be nil)
    children (array)  - Array of children (strings, numbers or other elements)

RETURN:
-------
    element (table)   - Element with configured metatable

EXAMPLE:
--------
    local elements = require("DaviLuaXML.elements")
    
    local button = elements:createElement(
        "button",
        { class = "primary", disabled = false },
        { "Click here" }
    )
    
    print(button.tag)           -- "button"
    print(button.props.class)   -- "primary"
    print(button.children[1])   -- "Click here"

METATABLE:
----------
    - __tostring: Converts element to string (tableToString)
    - __concat: Allows concatenating elements with ..
]=]

help.en.props = [=[
======================================================================
                          DaviLuaXML - Props                              
======================================================================

The props module converts between Lua tables and XML attribute strings.

FUNCTIONS:
----------

tableToPropsString(table)
    Converts a Lua table to XML attribute string.
    
    local props = require("DaviLuaXML.props")
    local s = props.tableToPropsString({ id = "btn1", count = 5 })
    print(s)  -- 'id="btn1" count="5"'

stringToPropsTable(string)
    Converts an XML attribute string to Lua table.
    Automatic type conversion (number, boolean).
    
    local props = require("DaviLuaXML.props")
    local t = props.stringToPropsTable('count="5" active="true"')
    print(t.count)   -- 5 (number)
    print(t.active)  -- true (boolean)

TYPE CONVERSION:
----------------
    String to Table:
    - "123"   becomes 123 (number)
    - "true"  becomes true (boolean)
    - "false" becomes false (boolean)
    - "text"  stays "text" (string)
]=]

help.en.errors = [=[
======================================================================
                         DaviLuaXML - Errors                              
======================================================================

The errors module formats error messages with context.

USAGE:
------
    local errors = require("DaviLuaXML.errors")

FUNCTIONS:
----------

errors.format(msg, file, code, position)
    Formats a generic error message.
    
errors.unclosedTag(tag, file, code, position)
    Error for unclosed tag.
    
errors.invalidTag(file, code, position)
    Error for invalid/malformed tag.
    
errors.compilationError(file, luaError)
    Compilation error for transformed code.
    
errors.runtimeError(file, luaError)
    Runtime error for the code.

errors.getLineInfo(code, position)
    Returns line number and column for a position.
    
errors.getLine(code, lineNumber)
    Returns the text of a specific line.

EXAMPLE:
--------
    local errors = require("DaviLuaXML.errors")
    
    local line, column = errors.getLineInfo("abc\ndef\nghi", 6)
    print(line, column)  -- 2, 2
    
    local msg = errors.unclosedTag("div", "app.dslx", code, 10)
    -- [DaviLuaXML] app.dslx: line 1, column 10: tag 'div' was not closed...
]=]

help.en.core = [=[
======================================================================
                          DaviLuaXML - Core                               
======================================================================

The core module loads and executes .dslx files directly.

USAGE:
------
    local core = require("DaviLuaXML.core")
    local result, err = core(path)

PARAMETERS:
-----------
    path (string) - Path to the .dslx file

RETURN:
-------
    result (string) - Transformed code (or nil if error)
    err (string)    - Error message (or nil if success)

EXAMPLE:
--------
    local core = require("DaviLuaXML.core")
    
    -- Execute the file and return the transformed code
    local code, err = core("my_app.dslx")
    
    if err then
        print("Error:", err)
    else
        print("Executed successfully!")
    end

PROCESS:
--------
    1. Read file from disk
    2. Transform XML to Lua
    3. Compile Lua code
    4. Execute the code
    5. Return transformed code or error
]=]

help.en.init = [=[
======================================================================
                          DaviLuaXML - Init                               
======================================================================

The init module registers a custom searcher for require().

USAGE:
------
    require("DaviLuaXML")  -- or require("DaviLuaXML.init")
    
    -- Now you can load .dslx files with require()
    local App = require("my_component")

HOW IT WORKS:
-------------
    1. Adds a searcher to package.searchers
    2. When require() is called, searches for .dslx file
    3. If found, transforms the code and returns the chunk

EXAMPLE:
--------
    -- main.lua
    require("DaviLuaXML")
    
    local config = require("config")      -- loads config.dslx
    local App = require("components.App") -- loads components/App.dslx

PROJECT STRUCTURE:
------------------
    project/
        main.lua          -- require("DaviLuaXML") here
        config.dslx
        components/
            App.dslx
            Button.dslx

NOTES:
------
    - The searcher uses package.path replacing .lua with .dslx
    - Works with dot paths (a.b.c becomes a/b/c.dslx)
    - The loaded module stays in package.loaded normally
]=]

help.en.middleware = [=[
======================================================================
                       DaviLuaXML - Middleware                            
======================================================================

The middleware module allows transforming props and children values
before they are serialized into function calls.

USAGE:
------
    local middleware = require("DaviLuaXML.middleware")
    
    -- Register a middleware for props
    middleware.addProp(function(value, ctx)
        -- transform and return new value
        return value
    end)
    
    -- Register a middleware for children
    middleware.addChild(function(value, ctx)
        -- transform and return new value
        return value
    end)

CONTEXT (ctx):
--------------
    For props:
        ctx.key   - Property name
        ctx.tag   - Tag name of the element
        ctx.props - All props of the element
    
    For children:
        ctx.index  - Child index (1-based)
        ctx.tag    - Tag name of the element
        ctx.parent - Parent element

FUNCTIONS:
----------
    addProp(fn)         - Register prop middleware
    addChild(fn)        - Register child middleware
    runProp(value, ctx) - Execute prop middlewares (internal)
    runChild(value, ctx)- Execute child middlewares (internal)

EXAMPLE:
--------
    local middleware = require("DaviLuaXML.middleware")
    
    -- Log all props during transformation
    middleware.addProp(function(value, ctx)
        print(string.format("Prop %s = %s in <%s>", 
            ctx.key, tostring(value), ctx.tag))
        return value  -- return unchanged
    end)
    
    -- Convert all string children to uppercase
    middleware.addChild(function(value, ctx)
        if type(value) == "string" then
            return value:upper()
        end
        return value
    end)

NOTES:
------
    - Middlewares are executed in registration order
    - If a middleware returns nil, the value is unchanged
    - Errors in middlewares are caught (pcall) and ignored
    - Middlewares run at transformation time, not runtime
]=]

--------------------------------------------------------------------------------
-- TEXTOS DE AJUDA - PORTUGUES
--------------------------------------------------------------------------------

help.pt = {}

help.pt.geral = [=[
======================================================================
                          DaviLuaXML - Ajuda                              
======================================================================

DaviLuaXML e uma biblioteca que permite usar sintaxe XML dentro de codigo Lua.
As tags XML sao transformadas em chamadas de funcao Lua.

INICIO RAPIDO:
--------------
    -- 1. Carregue o DaviLuaXML no inicio do programa
    require("DaviLuaXML")
    
    -- 2. Agora voce pode usar require() com arquivos .dslx
    local App = require("meu_componente")  -- carrega meu_componente.dslx

EXEMPLO BASICO:
---------------
    -- arquivo: app.dslx
    local function Botao(props, children)
        return string.format('<button class="%s">%s</button>', 
            props.class or "", 
            children[1] or "")
    end
    
    local html = <Botao class="primary">Clique aqui</Botao>
    print(html)  -- <button class="primary">Clique aqui</button>

TOPICOS DISPONIVEIS:
--------------------
Use help("topico") para mais informacoes:
    - geral      - Esta pagina
    - sintaxe    - Sintaxe XML suportada
    - parser     - Modulo de parsing
    - transform  - Modulo de transformacao
    - runtime    - Helper de runtime (invoke wrapper)
    - proptypes  - Validacao de props (PropTypes)
    - sourcemap  - Mapeamento de linhas para erros em .dslx
    - treeshake  - Tree-shaking (compilador)
    - compile    - Pre-compilacao .dslx -> .lua
    - elements   - Criacao de elementos
    - props      - Manipulacao de propriedades
    - middleware - Sistema de middleware para props/children
    - errors     - Sistema de erros
    - core       - Carregamento de arquivos
    - init       - Sistema de require

IDIOMA:
-------
Use help.lang("codigo") para mudar o idioma:
    - en - English
    - pt - Portugues
    - es - Espanol

Digite: require("DaviLuaXML.help").list() para listar todos os topicos.
]=]

help.pt.sintaxe = [=[
======================================================================
                       DaviLuaXML - Sintaxe XML                           
======================================================================

TAGS BASICAS:
-------------
    -- Tag self-closing (sem conteudo)
    <MinhaTag/>
    
    -- Tag com conteudo
    <MinhaTag>conteudo aqui</MinhaTag>
    
    -- Tags aninhadas
    <Pai>
        <Filho>texto</Filho>
    </Pai>

ATRIBUTOS:
----------
    -- Strings
    <Tag nome="valor"/>
    
    -- Sem aspas (valores simples)
    <Tag ativo=true count=5/>
    
    -- Expressoes Lua em chaves
    <Tag valor={10 + 5} lista={minhaTabela}/>

EXPRESSOES EM CONTEUDO:
-----------------------
    -- Expressoes Lua dentro de tags
    <Tag>{variavel}</Tag>
    <Tag>{1 + 2 + 3}</Tag>
    <Tag>{"string"}</Tag>
    
    -- Multiplas expressoes
    <Lista>{item1}{item2}{item3}</Lista>

NOMES COM PONTO:
----------------
    -- Acesso a modulos/namespaces
    <html.div class="container"/>
    <ui.Button onClick={handler}/>

TRANSFORMACAO:
--------------
    -- O codigo XML e transformado em chamadas roteadas por um helper:
    <Tag prop="valor">texto</Tag>
    
    -- Vira:
    __daviluaxml_invoke(Tag, 'Tag', {prop = 'valor'}, {[1] = 'texto'})
    
    -- A funcao recebe: (props, children)
]=]

help.pt.parser = [=[
======================================================================
                         DaviLuaXML - Parser                              
======================================================================

O modulo parser converte strings XML em tabelas Lua.

USO:
----
    local parser = require("DaviLuaXML.parser")
    local node, startPos, endPos = parser(codigo)

PARAMETROS:
-----------
    codigo (string)  - Codigo contendo uma tag XML

RETORNO:
--------
    node (table)     - Tabela representando o elemento:
                       { tag = string, props = table, children = array }
    startPos (number)- Posicao inicial da tag no codigo
    endPos (number)  - Posicao final da tag no codigo

EXEMPLO:
--------
    local parser = require("DaviLuaXML.parser")
    
    local node = parser('<div class="container"><span>texto</span></div>')
    
    print(node.tag)              -- "div"
    print(node.props.class)      -- "container"
    print(node.children[1].tag)  -- "span"
    print(node.children[1].children[1])  -- "texto"

ESTRUTURA DO NODE:
------------------
    {
        tag = "div",
        props = {
            class = "container"
        },
        children = {
            [1] = {
                tag = "span",
                props = {},
                children = { "texto" }
            }
        }
    }
]=]

help.pt.transform = [==[
======================================================================
                        DaviLuaXML - Transform                            
======================================================================

O modulo transform converte codigo Lua+XML em codigo Lua puro.

USO:
----
    local transform = require("DaviLuaXML.transform").transform
    local resultado, erro, map = transform(codigo, arquivo)

PARAMETROS:
-----------
    codigo (string)   - Codigo Lua contendo tags XML
    arquivo (string)  - Nome do arquivo (opcional, para mensagens de erro)

RETORNO:
--------
    resultado (string) - Codigo Lua transformado (ou nil se erro)
    erro (string)      - Mensagem de erro (ou nil se sucesso)
    map (table)         - Sourcemap simples (mapeamento de linhas)

EXEMPLO:
--------
    local transform = require("DaviLuaXML.transform").transform
    
    local codigo = [[
        local function Comp(props)
            return props.x * 2
        end
        local resultado = <Comp x={21}/>
    ]]
    
    local lua_puro = transform(codigo)
    print(lua_puro)

NOTAS:
------
    - Tags reservadas do Lua (const, close) sao preservadas
    - Multiplas tags podem existir no mesmo codigo
    - Expressoes em {} sao avaliadas durante a transformacao
    - Quando pelo menos uma tag e transformada, injeta:
        local __daviluaxml_invoke = require("DaviLuaXML.runtime").invoke
]==]

help.pt.runtime = [=[
======================================================================
                         DaviLuaXML - Runtime
======================================================================

O modulo runtime fornece helpers usados pelo codigo transformado.

O transformer gera chamadas como:
    __daviluaxml_invoke(tagExpr, 'tagName', props, children)

Isso habilita:
  - validacao de props (PropTypes)
  - invocacao consistente de funcoes / tabelas chamaveis
]=]

help.pt.proptypes = [=[
======================================================================
                        DaviLuaXML - PropTypes
======================================================================

PropTypes e um sistema opcional de validacao de props em runtime.

1) Registry (por nome da tag):
    local t = require("DaviLuaXML.proptypes")
    t.register("Botao", {
        label = t.string({ required = true }),
        disabled = t.boolean(),
    })

2) No componente (campo propTypes):
    local t = require("DaviLuaXML.proptypes")
    local Botao = setmetatable({
        propTypes = { label = t.string({ required = true }) }
    }, { __call = function(self, props, children) ... end })

Desligar validacao:
    require("DaviLuaXML.proptypes").enabled = false
]=]

help.pt.sourcemap = [=[
======================================================================
                        DaviLuaXML - Sourcemaps
======================================================================

O DaviLuaXML gera um mapeamento simples por linha ao transformar .dslx.

O loader (searcher do require) e o core reescrevem erros de runtime para
apontar para as linhas do .dslx original.

LIMITACOES:
-----------
E um mapeador leve por linha (nao e um sourcemap completo por coluna).
]=]

help.pt.treeshake = [=[
======================================================================
                       DaviLuaXML - Tree-shaking
======================================================================

Tree-shaking e um passo conservador do compilador.

Ele comenta linhas `local X = require("...")` que nao sao usadas no resto
do codigo.

USO (CLI):
---------
    dslxc --treeshake src/ dist/
]=]

help.pt.compile = [=[
======================================================================
                         DaviLuaXML - Compile
======================================================================

O modulo compile pre-compila arquivos .dslx para .lua puro.

USO:
----
    local compile = require("DaviLuaXML.compile")
    compile.file("app.dslx")
    compile.dir("src/", "dist/")

CLI:
----
    dslxc app.dslx
    dslxc src/ dist/

OPCOES:
-------
    --no-header   Nao adiciona header
    --treeshake   Comenta requires nao usados
]=]

help.pt.elements = [=[
======================================================================
                        DaviLuaXML - Elements                             
======================================================================

O modulo elements fornece funcoes para criar elementos programaticamente.

USO:
----
    local elements = require("DaviLuaXML.elements")
    local el = elements:createElement(tag, props, children)

PARAMETROS:
-----------
    tag (string)      - Nome da tag
    props (table)     - Tabela de propriedades (pode ser nil)
    children (array)  - Array de filhos (strings, numeros ou outros elementos)

RETORNO:
--------
    element (table)   - Elemento com metatable configurada

EXEMPLO:
--------
    local elements = require("DaviLuaXML.elements")
    
    local botao = elements:createElement(
        "button",
        { class = "primary", disabled = false },
        { "Clique aqui" }
    )
    
    print(botao.tag)           -- "button"
    print(botao.props.class)   -- "primary"
    print(botao.children[1])   -- "Clique aqui"

METATABLE:
----------
    - __tostring: Converte elemento para string (tableToString)
    - __concat: Permite concatenar elementos com ..
]=]

help.pt.props = [=[
======================================================================
                          DaviLuaXML - Props                              
======================================================================

O modulo props converte entre tabelas Lua e strings de atributos XML.

FUNCOES:
--------

tableToPropsString(tabela)
    Converte uma tabela Lua em string de atributos XML.
    
    local props = require("DaviLuaXML.props")
    local s = props.tableToPropsString({ id = "btn1", count = 5 })
    print(s)  -- 'id="btn1" count="5"'

stringToPropsTable(string)
    Converte uma string de atributos XML em tabela Lua.
    Faz conversao automatica de tipos (number, boolean).
    
    local props = require("DaviLuaXML.props")
    local t = props.stringToPropsTable('count="5" active="true"')
    print(t.count)   -- 5 (number)
    print(t.active)  -- true (boolean)

CONVERSAO DE TIPOS:
-------------------
    String para Tabela:
    - "123"   vira 123 (number)
    - "true"  vira true (boolean)
    - "false" vira false (boolean)
    - "texto" continua "texto" (string)
]=]

help.pt.errors = [=[
======================================================================
                         DaviLuaXML - Errors                              
======================================================================

O modulo errors formata mensagens de erro com contexto.

USO:
----
    local errors = require("DaviLuaXML.errors")

FUNCOES:
--------

errors.format(msg, arquivo, codigo, posicao)
    Formata uma mensagem de erro generica.
    
errors.unclosedTag(tag, arquivo, codigo, posicao)
    Erro para tag nao fechada.
    
errors.invalidTag(arquivo, codigo, posicao)
    Erro para tag invalida/malformada.
    
errors.compilationError(arquivo, luaError)
    Erro de compilacao do codigo transformado.
    
errors.runtimeError(arquivo, luaError)
    Erro de execucao do codigo.

errors.getLineInfo(codigo, posicao)
    Retorna numero da linha e coluna para uma posicao.
    
errors.getLine(codigo, numeroLinha)
    Retorna o texto de uma linha especifica.

EXEMPLO:
--------
    local errors = require("DaviLuaXML.errors")
    
    local linha, coluna = errors.getLineInfo("abc\ndef\nghi", 6)
    print(linha, coluna)  -- 2, 2
    
    local msg = errors.unclosedTag("div", "app.dslx", codigo, 10)
    -- [DaviLuaXML] app.dslx: linha 1, coluna 10: tag 'div' nao foi fechada...
]=]

help.pt.core = [=[
======================================================================
                          DaviLuaXML - Core                               
======================================================================

O modulo core carrega e executa arquivos .dslx diretamente.

USO:
----
    local core = require("DaviLuaXML.core")
    local resultado, erro = core(caminho)

PARAMETROS:
-----------
    caminho (string) - Caminho para o arquivo .dslx

RETORNO:
--------
    resultado (string) - Codigo transformado (ou nil se erro)
    erro (string)      - Mensagem de erro (ou nil se sucesso)

EXEMPLO:
--------
    local core = require("DaviLuaXML.core")
    
    -- Executa o arquivo e retorna o codigo transformado
    local codigo, err = core("meu_app.dslx")
    
    if err then
        print("Erro:", err)
    else
        print("Executado com sucesso!")
    end

PROCESSO:
---------
    1. Le o arquivo do disco
    2. Transforma XML para Lua
    3. Compila o codigo Lua
    4. Executa o codigo
    5. Retorna o codigo transformado ou erro
]=]

help.pt.init = [=[
======================================================================
                          DaviLuaXML - Init                               
======================================================================

O modulo init registra um searcher customizado para require().

USO:
----
    require("DaviLuaXML")  -- ou require("DaviLuaXML.init")
    
    -- Agora voce pode carregar arquivos .dslx com require()
    local App = require("meu_componente")

FUNCIONAMENTO:
--------------
    1. Adiciona um searcher em package.searchers
    2. Quando require() e chamado, procura por arquivo .dslx
    3. Se encontrar, transforma o codigo e retorna o chunk

EXEMPLO:
--------
    -- main.lua
    require("DaviLuaXML")
    
    local config = require("config")      -- carrega config.dslx
    local App = require("components.App") -- carrega components/App.dslx

ESTRUTURA DE PROJETO:
---------------------
    projeto/
        main.lua          -- require("DaviLuaXML") aqui
        config.dslx
        components/
            App.dslx
            Button.dslx

NOTAS:
------
    - O searcher usa package.path trocando .lua por .dslx
    - Funciona com caminhos com ponto (a.b.c vira a/b/c.dslx)
    - O modulo carregado fica em package.loaded normalmente
]=]

help.pt.middleware = [=[
======================================================================
                       DaviLuaXML - Middleware                            
======================================================================

O modulo middleware permite transformar valores de props e children
antes de serem serializados em chamadas de funcao.

USO:
----
    local middleware = require("DaviLuaXML.middleware")
    
    -- Registrar um middleware para props
    middleware.addProp(function(value, ctx)
        -- transformar e retornar novo valor
        return value
    end)
    
    -- Registrar um middleware para children
    middleware.addChild(function(value, ctx)
        -- transformar e retornar novo valor
        return value
    end)

CONTEXTO (ctx):
---------------
    Para props:
        ctx.key   - Nome da propriedade
        ctx.tag   - Nome da tag do elemento
        ctx.props - Todas as props do elemento
    
    Para children:
        ctx.index  - Indice do filho (comeca em 1)
        ctx.tag    - Nome da tag do elemento
        ctx.parent - Elemento pai

FUNCOES:
--------
    addProp(fn)         - Registrar middleware de prop
    addChild(fn)        - Registrar middleware de child
    runProp(value, ctx) - Executar middlewares de prop (interno)
    runChild(value, ctx)- Executar middlewares de child (interno)

EXEMPLO:
--------
    local middleware = require("DaviLuaXML.middleware")
    
    -- Logar todas as props durante a transformacao
    middleware.addProp(function(value, ctx)
        print(string.format("Prop %s = %s em <%s>", 
            ctx.key, tostring(value), ctx.tag))
        return value  -- retorna sem alteracao
    end)
    
    -- Converter todos os children string para maiusculo
    middleware.addChild(function(value, ctx)
        if type(value) == "string" then
            return value:upper()
        end
        return value
    end)

NOTAS:
------
    - Middlewares sao executados na ordem de registro
    - Se um middleware retornar nil, o valor nao e alterado
    - Erros em middlewares sao capturados (pcall) e ignorados
    - Middlewares rodam no momento da transformacao, nao em runtime
]=]

--------------------------------------------------------------------------------
-- TEXTOS DE AJUDA - ESPANOL
--------------------------------------------------------------------------------

help.es = {}

help.es.general = [=[
======================================================================
                          DaviLuaXML - Ayuda                              
======================================================================

DaviLuaXML es una biblioteca que permite usar sintaxis XML dentro de codigo Lua.
Las etiquetas XML se transforman en llamadas de funcion Lua.

INICIO RAPIDO:
--------------
    -- 1. Carga DaviLuaXML al inicio del programa
    require("DaviLuaXML")
    
    -- 2. Ahora puedes usar require() con archivos .dslx
    local App = require("mi_componente")  -- carga mi_componente.dslx

EJEMPLO BASICO:
---------------
    -- archivo: app.dslx
    local function Boton(props, children)
        return string.format('<button class="%s">%s</button>', 
            props.class or "", 
            children[1] or "")
    end
    
    local html = <Boton class="primary">Haz clic aqui</Boton>
    print(html)  -- <button class="primary">Haz clic aqui</button>

TEMAS DISPONIBLES:
------------------
Usa help("tema") para mas informacion:
    - general    - Esta pagina
    - sintaxis   - Sintaxis XML soportada
    - parser     - Modulo de parsing
    - transform  - Modulo de transformacion
    - runtime    - Helper de runtime (invoke wrapper)
    - proptypes  - Validacion de props (PropTypes)
    - sourcemap  - Mapeo de lineas para errores en .dslx
    - treeshake  - Tree-shaking (compilador)
    - compile    - Pre-compilacion .dslx -> .lua
    - elements   - Creacion de elementos
    - props      - Manejo de propiedades
    - middleware - Sistema de middleware para props/children
    - errors     - Sistema de errores
    - core       - Carga de archivos
    - init       - Sistema de require

IDIOMA:
-------
Usa help.lang("codigo") para cambiar el idioma:
    - en - English
    - pt - Portugues
    - es - Espanol

Escribe: require("DaviLuaXML.help").list() para listar todos los temas.
]=]

help.es.sintaxis = [=[
======================================================================
                       DaviLuaXML - Sintaxis XML                           
======================================================================

ETIQUETAS BASICAS:
------------------
    -- Etiqueta self-closing (sin contenido)
    <MiEtiqueta/>
    
    -- Etiqueta con contenido
    <MiEtiqueta>contenido aqui</MiEtiqueta>
    
    -- Etiquetas anidadas
    <Padre>
        <Hijo>texto</Hijo>
    </Padre>

ATRIBUTOS:
----------
    -- Strings
    <Tag nombre="valor"/>
    
    -- Sin comillas (valores simples)
    <Tag activo=true count=5/>
    
    -- Expresiones Lua entre llaves
    <Tag valor={10 + 5} lista={miTabla}/>

EXPRESIONES EN CONTENIDO:
-------------------------
    -- Expresiones Lua dentro de etiquetas
    <Tag>{variable}</Tag>
    <Tag>{1 + 2 + 3}</Tag>
    <Tag>{"string"}</Tag>
    
    -- Multiples expresiones
    <Lista>{item1}{item2}{item3}</Lista>

NOMBRES CON PUNTO:
------------------
    -- Acceso a modulos/namespaces
    <html.div class="container"/>
    <ui.Button onClick={handler}/>

TRANSFORMACION:
---------------
    -- El codigo XML se transforma y se enruta por un helper:
    <Tag prop="valor">texto</Tag>
    
    -- Se convierte en:
    __daviluaxml_invoke(Tag, 'Tag', {prop = 'valor'}, {[1] = 'texto'})
    
    -- La funcion recibe: (props, children)
]=]

help.es.parser = [=[
======================================================================
                         DaviLuaXML - Parser                              
======================================================================

El modulo parser convierte strings XML en tablas Lua.

USO:
----
    local parser = require("DaviLuaXML.parser")
    local node, startPos, endPos = parser(codigo)

PARAMETROS:
-----------
    codigo (string)  - Codigo que contiene una etiqueta XML

RETORNO:
--------
    node (table)     - Tabla que representa el elemento:
                       { tag = string, props = table, children = array }
    startPos (number)- Posicion inicial de la etiqueta en el codigo
    endPos (number)  - Posicion final de la etiqueta en el codigo

EJEMPLO:
--------
    local parser = require("DaviLuaXML.parser")
    
    local node = parser('<div class="container"><span>texto</span></div>')
    
    print(node.tag)              -- "div"
    print(node.props.class)      -- "container"
    print(node.children[1].tag)  -- "span"
    print(node.children[1].children[1])  -- "texto"

ESTRUCTURA DEL NODE:
--------------------
    {
        tag = "div",
        props = {
            class = "container"
        },
        children = {
            [1] = {
                tag = "span",
                props = {},
                children = { "texto" }
            }
        }
    }
]=]

help.es.transform = [==[
======================================================================
                        DaviLuaXML - Transform                            
======================================================================

El modulo transform convierte codigo Lua+XML en codigo Lua puro.

USO:
----
    local transform = require("DaviLuaXML.transform").transform
    local resultado, error, map = transform(codigo, archivo)

PARAMETROS:
-----------
    codigo (string)   - Codigo Lua que contiene etiquetas XML
    archivo (string)  - Nombre del archivo (opcional, para mensajes de error)

RETORNO:
--------
    resultado (string) - Codigo Lua transformado (o nil si hay error)
    error (string)     - Mensaje de error (o nil si exito)
    map (table)         - Sourcemap simple (mapeo de lineas)

EJEMPLO:
--------
    local transform = require("DaviLuaXML.transform").transform
    
    local codigo = [[
        local function Comp(props)
            return props.x * 2
        end
        local resultado = <Comp x={21}/>
    ]]
    
    local lua_puro = transform(codigo)
    print(lua_puro)

NOTAS:
------
    - Las etiquetas reservadas de Lua (const, close) se preservan
    - Multiples etiquetas pueden existir en el mismo codigo
    - Las expresiones en {} se evaluan durante la transformacion
    - Cuando al menos una etiqueta se transforma, inyecta:
        local __daviluaxml_invoke = require("DaviLuaXML.runtime").invoke
]==]

help.es.runtime = [=[
======================================================================
                         DaviLuaXML - Runtime
======================================================================

El modulo runtime provee helpers usados por el codigo transformado.

El transformer genera llamadas como:
    __daviluaxml_invoke(tagExpr, 'tagName', props, children)

Esto habilita:
  - validacion de props (PropTypes)
  - invocacion consistente de funciones / tablas llamables
]=]

help.es.proptypes = [=[
======================================================================
                        DaviLuaXML - PropTypes
======================================================================

PropTypes es un sistema opcional de validacion de props en runtime.

1) Registry (por nombre de la etiqueta):
    local t = require("DaviLuaXML.proptypes")
    t.register("Boton", {
        label = t.string({ required = true }),
        disabled = t.boolean(),
    })

2) En el componente (campo propTypes):
    local t = require("DaviLuaXML.proptypes")
    local Boton = setmetatable({
        propTypes = { label = t.string({ required = true }) }
    }, { __call = function(self, props, children) ... end })

Desactivar validacion:
    require("DaviLuaXML.proptypes").enabled = false
]=]

help.es.sourcemap = [=[
======================================================================
                        DaviLuaXML - Sourcemaps
======================================================================

DaviLuaXML genera un mapeo simple por linea al transformar .dslx.

El loader (searcher del require) y el core reescriben errores de runtime
para apuntar a las lineas del .dslx original.

LIMITACIONES:
------------
Es un mapeador ligero por linea (no es un sourcemap completo por columna).
]=]

help.es.treeshake = [=[
======================================================================
                       DaviLuaXML - Tree-shaking
======================================================================

Tree-shaking es un paso conservador del compilador.

Comenta lineas `local X = require("...")` que no se usan en el resto del codigo.

USO (CLI):
---------
    dslxc --treeshake src/ dist/
]=]

help.es.compile = [=[
======================================================================
                         DaviLuaXML - Compile
======================================================================

El modulo compile pre-compila archivos .dslx a .lua puro.

USO:
----
    local compile = require("DaviLuaXML.compile")
    compile.file("app.dslx")
    compile.dir("src/", "dist/")

CLI:
----
    dslxc app.dslx
    dslxc src/ dist/

OPCIONES:
--------
    --no-header   No agrega header
    --treeshake   Comenta requires no usados
]=]

help.es.elements = [=[
======================================================================
                        DaviLuaXML - Elements                             
======================================================================

El modulo elements proporciona funciones para crear elementos programaticamente.

USO:
----
    local elements = require("DaviLuaXML.elements")
    local el = elements:createElement(tag, props, children)

PARAMETROS:
-----------
    tag (string)      - Nombre de la etiqueta
    props (table)     - Tabla de propiedades (puede ser nil)
    children (array)  - Array de hijos (strings, numeros u otros elementos)

RETORNO:
--------
    element (table)   - Elemento con metatable configurada

EJEMPLO:
--------
    local elements = require("DaviLuaXML.elements")
    
    local boton = elements:createElement(
        "button",
        { class = "primary", disabled = false },
        { "Haz clic aqui" }
    )
    
    print(boton.tag)           -- "button"
    print(boton.props.class)   -- "primary"
    print(boton.children[1])   -- "Haz clic aqui"

METATABLE:
----------
    - __tostring: Convierte elemento a string (tableToString)
    - __concat: Permite concatenar elementos con ..
]=]

help.es.props = [=[
======================================================================
                          DaviLuaXML - Props                              
======================================================================

El modulo props convierte entre tablas Lua y strings de atributos XML.

FUNCIONES:
----------

tableToPropsString(tabla)
    Convierte una tabla Lua a string de atributos XML.
    
    local props = require("DaviLuaXML.props")
    local s = props.tableToPropsString({ id = "btn1", count = 5 })
    print(s)  -- 'id="btn1" count="5"'

stringToPropsTable(string)
    Convierte un string de atributos XML a tabla Lua.
    Conversion automatica de tipos (number, boolean).
    
    local props = require("DaviLuaXML.props")
    local t = props.stringToPropsTable('count="5" active="true"')
    print(t.count)   -- 5 (number)
    print(t.active)  -- true (boolean)

CONVERSION DE TIPOS:
--------------------
    String a Tabla:
    - "123"   se convierte en 123 (number)
    - "true"  se convierte en true (boolean)
    - "false" se convierte en false (boolean)
    - "texto" permanece "texto" (string)
]=]

help.es.errors = [=[
======================================================================
                         DaviLuaXML - Errors                              
======================================================================

El modulo errors formatea mensajes de error con contexto.

USO:
----
    local errors = require("DaviLuaXML.errors")

FUNCIONES:
----------

errors.format(msg, archivo, codigo, posicion)
    Formatea un mensaje de error generico.
    
errors.unclosedTag(tag, archivo, codigo, posicion)
    Error para etiqueta no cerrada.
    
errors.invalidTag(archivo, codigo, posicion)
    Error para etiqueta invalida/malformada.
    
errors.compilationError(archivo, luaError)
    Error de compilacion del codigo transformado.
    
errors.runtimeError(archivo, luaError)
    Error de ejecucion del codigo.

errors.getLineInfo(codigo, posicion)
    Retorna numero de linea y columna para una posicion.
    
errors.getLine(codigo, numeroLinea)
    Retorna el texto de una linea especifica.

EJEMPLO:
--------
    local errors = require("DaviLuaXML.errors")
    
    local linea, columna = errors.getLineInfo("abc\ndef\nghi", 6)
    print(linea, columna)  -- 2, 2
    
    local msg = errors.unclosedTag("div", "app.dslx", codigo, 10)
    -- [DaviLuaXML] app.dslx: linea 1, columna 10: etiqueta 'div' no fue cerrada...
]=]

help.es.core = [=[
======================================================================
                          DaviLuaXML - Core                               
======================================================================

El modulo core carga y ejecuta archivos .dslx directamente.

USO:
----
    local core = require("DaviLuaXML.core")
    local resultado, error = core(ruta)

PARAMETROS:
-----------
    ruta (string) - Ruta al archivo .dslx

RETORNO:
--------
    resultado (string) - Codigo transformado (o nil si hay error)
    error (string)     - Mensaje de error (o nil si exito)

EJEMPLO:
--------
    local core = require("DaviLuaXML.core")
    
    -- Ejecuta el archivo y retorna el codigo transformado
    local codigo, err = core("mi_app.dslx")
    
    if err then
        print("Error:", err)
    else
        print("Ejecutado exitosamente!")
    end

PROCESO:
--------
    1. Lee el archivo del disco
    2. Transforma XML a Lua
    3. Compila el codigo Lua
    4. Ejecuta el codigo
    5. Retorna codigo transformado o error
]=]

help.es.init = [=[
======================================================================
                          DaviLuaXML - Init                               
======================================================================

El modulo init registra un searcher personalizado para require().

USO:
----
    require("DaviLuaXML")  -- o require("DaviLuaXML.init")
    
    -- Ahora puedes cargar archivos .dslx con require()
    local App = require("mi_componente")

FUNCIONAMIENTO:
---------------
    1. Agrega un searcher a package.searchers
    2. Cuando se llama require(), busca un archivo .dslx
    3. Si lo encuentra, transforma el codigo y retorna el chunk

EJEMPLO:
--------
    -- main.lua
    require("DaviLuaXML")
    
    local config = require("config")      -- carga config.dslx
    local App = require("components.App") -- carga components/App.dslx

ESTRUCTURA DE PROYECTO:
-----------------------
    proyecto/
        main.lua          -- require("DaviLuaXML") aqui
        config.dslx
        components/
            App.dslx
            Button.dslx

NOTAS:
------
    - El searcher usa package.path reemplazando .lua por .dslx
    - Funciona con rutas con punto (a.b.c se convierte en a/b/c.dslx)
    - El modulo cargado queda en package.loaded normalmente
]=]

help.es.middleware = [=[
======================================================================
                       DaviLuaXML - Middleware                            
======================================================================

El modulo middleware permite transformar valores de props y children
antes de ser serializados en llamadas de funcion.

USO:
----
    local middleware = require("DaviLuaXML.middleware")
    
    -- Registrar un middleware para props
    middleware.addProp(function(value, ctx)
        -- transformar y retornar nuevo valor
        return value
    end)
    
    -- Registrar un middleware para children
    middleware.addChild(function(value, ctx)
        -- transformar y retornar nuevo valor
        return value
    end)

CONTEXTO (ctx):
---------------
    Para props:
        ctx.key   - Nombre de la propiedad
        ctx.tag   - Nombre de la etiqueta del elemento
        ctx.props - Todas las props del elemento
    
    Para children:
        ctx.index  - Indice del hijo (comienza en 1)
        ctx.tag    - Nombre de la etiqueta del elemento
        ctx.parent - Elemento padre

FUNCIONES:
----------
    addProp(fn)         - Registrar middleware de prop
    addChild(fn)        - Registrar middleware de child
    runProp(value, ctx) - Ejecutar middlewares de prop (interno)
    runChild(value, ctx)- Ejecutar middlewares de child (interno)

EJEMPLO:
--------
    local middleware = require("DaviLuaXML.middleware")
    
    -- Registrar todas las props durante la transformacion
    middleware.addProp(function(value, ctx)
        print(string.format("Prop %s = %s en <%s>", 
            ctx.key, tostring(value), ctx.tag))
        return value  -- retorna sin cambios
    end)
    
    -- Convertir todos los children string a mayusculas
    middleware.addChild(function(value, ctx)
        if type(value) == "string" then
            return value:upper()
        end
        return value
    end)

NOTAS:
------
    - Los middlewares se ejecutan en orden de registro
    - Si un middleware retorna nil, el valor no se altera
    - Errores en middlewares son capturados (pcall) e ignorados
    - Los middlewares se ejecutan en el momento de la transformacion, no en runtime
]=]

--------------------------------------------------------------------------------
-- FUNCOES
--------------------------------------------------------------------------------

--- Obtem o texto de ajuda para um topico no idioma atual.
--- @param topic string Nome do topico
--- @return string|nil Texto de ajuda ou nil se nao encontrado
local function getTopicText(topic)
    local lang = help.currentLang
    local langTable = help[lang]
    
    if not langTable then
        langTable = help.en
    end
    
    -- Tentar encontrar o topico diretamente
    if langTable[topic] then
        return langTable[topic]
    end
    
    -- Fallback para ingles
    if help.en[topic] then
        return help.en[topic]
    end
    
    return nil
end

--- Lista todos os topicos de ajuda disponiveis.
function help.list()
    local lang = help.currentLang
    local langTable = help[lang] or help.en
    
    local headers = {
        en = { title = "\nAvailable help topics:", use = 'Use: require("DaviLuaXML.help")("topic")' },
        pt = { title = "\nTopicos de ajuda disponiveis:", use = 'Use: require("DaviLuaXML.help")("topico")' },
        es = { title = "\nTemas de ayuda disponibles:", use = 'Usa: require("DaviLuaXML.help")("tema")' }
    }
    
    local header = headers[lang] or headers.en
    
    print(header.title)
    print(string.rep("-", 40))
    
    local topics = {}
    for name in pairs(langTable) do
        if type(langTable[name]) == "string" then
            table.insert(topics, name)
        end
    end
    table.sort(topics)
    
    for _, name in ipairs(topics) do
        print("  - " .. name)
    end
    
    print(string.rep("-", 40))
    print(header.use)
    print("")
end

--- Exibe a ajuda de um topico especifico.
--- @param topic string|nil Nome do topico (nil para ajuda geral)
function help.show(topic)
    local defaultTopics = { en = "general", pt = "geral", es = "general" }
    topic = topic or defaultTopics[help.currentLang] or "general"
    
    local text = getTopicText(topic)
    
    if text then
        print(text)
    else
        local msgs = {
            en = "\n[DaviLuaXML] Topic '%s' not found.\n",
            pt = "\n[DaviLuaXML] Topico '%s' nao encontrado.\n",
            es = "\n[DaviLuaXML] Tema '%s' no encontrado.\n"
        }
        local msg = msgs[help.currentLang] or msgs.en
        print(string.format(msg, topic))
        help.list()
    end
end

--------------------------------------------------------------------------------
-- METATABLE
--------------------------------------------------------------------------------

setmetatable(help, {
    __call = function(_, topic)
        help.show(topic)
    end
})

return help
