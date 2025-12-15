# Davi System Lua XML (DaviLuaXML)

XML syntax for Lua - write XML directly in your Lua code, similar to JSX in JavaScript.

[![LuaRocks](https://img.shields.io/luarocks/v/pessoa736/daviluaxml)](https://luarocks.org/modules/pessoa736/daviluaxml)

**🌐 Language / Idioma / Idioma:** [English](README.md) | [Português](README.pt-BR.md) | [Español](README.es.md)

## Installation

```bash
luarocks install daviluaxml
```

## Basic Usage

```lua
-- Register the loader for .dslx files
require("DaviLuaXML")

-- Now you can use require() with .dslx files
local App = require("my_component")
```

### Example .dslx file

```lua
-- component.dslx
local function Button(props, children)
    return string.format('<button class="%s">%s</button>', 
        props.class, 
        children[1]
    )
end

local function App()
    return <div class="container">
        <h1>Hello World!</h1>
        <Button class="primary">Click here</Button>
    </div>
end

return App
```

## How It Works

DaviLuaXML transforms XML tags into Lua function calls:

```lua
-- This:
local el = <div class="container">Hello</div>

-- Becomes:
local el = div({class = "container"}, {"Hello"})
```

The function receives two arguments:

- `props` - table with the attributes
- `children` - table with the children (text, numbers or other elements)

## XML Syntax

### Simple tags

```lua
<div/>                          -- Self-closing tag
<p>text</p>                     -- Tag with content
```

### Attributes

```lua
<btn class="primary"/>          -- String
<input value={variable}/>       -- Lua expression
<comp enabled/>                 -- Boolean (true)
```

### Expressions in braces

```lua
<sum>{1}{2}{3}</sum>            -- Multiple values
<p>{name .. " " .. surname}</p> -- Lua expressions
```

### Nested tags

```lua
<div>
    <span>text</span>
    <ul>
        <li>item 1</li>
        <li>item 2</li>
    </ul>
</div>
```

### Tags with dot (namespaces)

```lua
<html.div class="x"/>           -- Becomes: html.div({class = "x"}, {})
```

## API

### require("DaviLuaXML")

Registers the loader for `.dslx` files. After that, `require()` works with `.dslx` files.

### require("DaviLuaXML.core")

```lua
local lx = require("DaviLuaXML.core")
local result, err = lx("file.dslx")
```

Directly executes an `.dslx` file by path.

### require("DaviLuaXML.help")

```lua
local help = require("DaviLuaXML.help")
help()              -- General help
help("syntax")      -- Specific topic
help.list()         -- List topics
help.lang("en")     -- Set language (en, pt, es)
```

## Logging (Debug)

DaviLuaXML uses [loglua](https://github.com/pessoa736/loglua) for logging. Debug logs are in the `XMLRuntime` section:

```lua
require("DaviLuaXML")
require("my_module")

-- Show runtime debug logs
log.show("XMLRuntime")
```

## Modules

| Module | Description |
|--------|-------------|
| `init` | Registers the searcher for require() |
| `core` | Directly executes .dslx files |
| `parser` | Parses XML tags |
| `transform` | Transforms XML to Lua |
| `elements` | Creates elements (tables) |
| `props` | Processes attributes |
| `errors` | Error formatting |
| `help` | Help system |

## Tests

```bash
lua DaviLuaXML/test/run_all.lua
```

## Dependencies

- Lua >= 5.4
- [loglua](https://github.com/pessoa736/loglua)

## License

MIT
