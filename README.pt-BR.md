# Davi System Lua XML (DaviLuaXML)

Sintaxe XML para Lua - escreva XML diretamente no seu código Lua, similar ao JSX no JavaScript.

[![LuaRocks](https://img.shields.io/luarocks/v/pessoa736/daviluaxml)](https://luarocks.org/modules/pessoa736/daviluaxml)

**🌐 Language / Idioma / Idioma:** [English](README.md) | [Português](README.pt-BR.md) | [Español](README.es.md)

## Instalação

```bash
luarocks install daviluaxml
```

## Uso Básico

```lua
-- Registrar o loader para arquivos .dslx
require("DaviLuaXML")

-- Agora você pode usar require() com arquivos .dslx
local App = require("meu_componente")
```

### Exemplo de arquivo .dslx

```lua
-- componente.dslx
local function Botao(props, children)
    return string.format('<button class="%s">%s</button>', 
        props.class, 
        children[1]
    )
end

local function App()
    return <div class="container">
        <h1>Olá Mundo!</h1>
        <Botao class="primary">Clique aqui</Botao>
    </div>
end

return App
```

## Como Funciona

O DaviLuaXML transforma tags XML em chamadas de função Lua:

```lua
-- Isso:
local el = <div class="container">Olá</div>

-- Vira isso:
local el = div({class = "container"}, {"Olá"})
```

A função recebe dois argumentos:

- `props` - tabela com os atributos
- `children` - tabela com os filhos (texto, números ou outros elementos)

## Sintaxe XML

### Tags simples

```lua
<div/>                          -- Tag self-closing
<p>texto</p>                    -- Tag com conteúdo
```

### Atributos

```lua
<btn class="primary"/>          -- String
<input value={variavel}/>       -- Expressão Lua
<comp enabled/>                 -- Booleano (true)
```

### Expressões em chaves

```lua
<soma>{1}{2}{3}</soma>          -- Múltiplos valores
<p>{nome .. " " .. sobrenome}</p>  -- Expressões Lua
```

### Tags aninhadas

```lua
<div>
    <span>texto</span>
    <ul>
        <li>item 1</li>
        <li>item 2</li>
    </ul>
</div>
```

### Tags com ponto (namespaces)

```lua
<html.div class="x"/>           -- Vira: html.div({class = "x"}, {})
```

## API

### require("DaviLuaXML")

Registra o loader para arquivos `.dslx`. Após isso, `require()` funciona com arquivos `.dslx`.

### require("DaviLuaXML.core")

```lua
local lx = require("DaviLuaXML.core")
local resultado, erro = lx("arquivo.dslx")
```

Executa diretamente um arquivo `.dslx` pelo caminho.

### require("DaviLuaXML.help")

```lua
local help = require("DaviLuaXML.help")
help()              -- Ajuda geral
help("sintaxe")     -- Tópico específico
help.list()         -- Listar tópicos
help.lang("pt")     -- Definir idioma (en, pt, es)
```

## Logging (Debug)

DaviLuaXML usa [loglua](https://github.com/pessoa736/loglua) para logging. Os logs de debug ficam na seção `XMLRuntime`:

```lua
require("DaviLuaXML")
require("meu_modulo")

-- Ver logs de debug do runtime
log.show("XMLRuntime")
```

## Módulos

| Módulo | Descrição |
|--------|-----------|
| `init` | Registra o searcher para require() |
| `core` | Executa arquivos .dslx diretamente |
| `parser` | Faz parse de tags XML |
| `transform` | Transforma XML em Lua |
| `elements` | Cria elementos (tabelas) |
| `props` | Processa atributos |
| `errors` | Formatação de erros |
| `help` | Sistema de ajuda |

## Testes

```bash
lua DaviLuaXML/test/run_all.lua
```

## Dependências

- Lua >= 5.4
- [loglua](https://github.com/pessoa736/loglua)

## Licença

MIT
