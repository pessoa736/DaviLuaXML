# Copilot Instructions - Davi System Lua XML (DaviLuaXML)

## Sobre o Projeto

Davi System Lua XML (DaviLuaXML) é uma biblioteca Lua que permite usar sintaxe XML diretamente no código Lua, similar ao JSX no JavaScript. Transforma `<tag attr="x">` em `tag({attr = "x"}, {})`.

- **Linguagem:** Lua 5.4+ (use `<const>`, `<close>` quando apropriado)
- **Gerenciador de pacotes:** LuaRocks
- **Logging:** loglua (global em `_G.log`)
- **Repositório:** https://github.com/pessoa736/DaviLuaXML
- **LuaRocks:** https://luarocks.org/modules/pessoa736/daviluaxml

## Estrutura do Projeto

```
DaviLuaXML/
├── init.lua          # Registra o searcher para require()
├── core.lua          # Executa arquivos .dslx diretamente
├── parser.lua        # Parse de tags XML
├── transform.lua     # Transforma XML em Lua
├── elements.lua      # Cria elementos (tabelas)
├── props.lua         # Processa atributos
├── errors.lua        # Formatação de erros
├── help.lua          # Sistema de ajuda
├── readFile.lua      # Leitura de arquivos
├── tableToString.lua # Serialização de tabelas
└── test/             # Testes unitários
rockspecs/            # Especificações do LuaRocks
```

## Ao Implementar uma Nova Feature

### Antes de começar:
1. Verificar a versão atual no rockspec mais recente em `rockspecs/`
2. Verificar se o código está atualizado com o repositório remoto
3. Entender o padrão de código existente (documentação com `---@param`, `---@return`)

### Durante o desenvolvimento:
1. Usar logging com `log.inSection("XMLRuntime")` para debug
2. Sempre verificar `if not _G.log then _G.log = require("loglua") end` antes de usar log
3. Seguir o padrão de documentação existente com comentários `--[[]]` e annotations

### Depois de implementar:
1. Criar/atualizar testes em `DaviLuaXML/test/`
2. Rodar todos os testes: `lua DaviLuaXML/test/run_all.lua`
3. Se todos os testes passarem, seguir para o upload

## Processo de Upload/Release

### Commits:
- Commits separados por mudança lógica
- Mensagem informal, em um parágrafo só
- Exemplo: `adicionei suporte pra tags com namespace tipo html.div, agora funciona certinho`

### Versionamento (padrão `x.y-z`):
- **Feature adicionada:** incrementar `y` → `x.(y+1)-1`
- **Bug corrigido:** incrementar `z` → `x.y-(z+1)`
- **Breaking change:** incrementar `x` → `(x+1).0-1`

### Passos do release:
1. Atualizar o rockspec:
   - Criar novo arquivo `rockspecs/daviluaxml-X.Y-Z.rockspec`
   - Atualizar versão e tag
2. Commit das mudanças
3. Criar tag git: `git tag X.Y-Z`
4. Push com tags: `git push && git push --tags`
5. Upload no LuaRocks: `luarocks upload rockspecs/daviluaxml-X.Y-Z.rockspec`

## Padrões de Código

### Documentação de funções:
```lua
--- Descrição breve da função.
--- Descrição mais detalhada se necessário.
---
--- @param nome tipo Descrição do parâmetro
--- @return tipo Descrição do retorno
local function minhaFuncao(nome)
    -- implementação
end
```

### Uso de log:

**IMPORTANTE:** Antes de usar qualquer função do loglua, consulte `log.help()` no terminal Lua para ver todas as funções disponíveis e como usá-las:
```lua
require("loglua").help()
```

Uso básico:
```lua
if not _G.log then _G.log = require("loglua") end
local logDebug = _G.log.inSection("XMLRuntime")

logDebug("mensagem de debug", variavel)
```

### Tratamento de erros:
```lua
local errors = require("DaviLuaXML.errors")
-- Usar errors.parseError(), errors.compilationError(), etc.
```

## Testes

Cada módulo tem seu teste correspondente em `DaviLuaXML/test/`:
- `test/parser.lua` - Testes do parser
- `test/transform.lua` - Testes de transformação
- `test/elements.lua` - Testes de elementos
- etc.

Padrão de teste:
```lua
local function test_nome_do_teste()
    -- arrange
    local input = "..."
    
    -- act
    local result = funcao(input)
    
    -- assert
    assert(result == esperado, "mensagem de erro")
end
```

## Comandos Úteis

```bash
# Rodar todos os testes
lua DaviLuaXML/test/run_all.lua

# Testar transformação manualmente
lua -e 'print(require("DaviLuaXML.transform").transform("<div/>"))'

# Instalar localmente para teste
luarocks make rockspecs/daviluaxml-dev-9.rockspec --local

# Upload para LuaRocks
luarocks upload rockspecs/daviluaxml-X.Y-Z.rockspec --api-key=CHAVE
```
