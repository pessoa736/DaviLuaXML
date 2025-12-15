# Davi System Lua XML (DaviLuaXML)

Sintaxis XML para Lua - escribe XML directamente en tu código Lua, similar a JSX en JavaScript.

[![LuaRocks](https://img.shields.io/luarocks/v/pessoa736/daviluaxml)](https://luarocks.org/modules/pessoa736/daviluaxml)

**🌐 Language / Idioma / Idioma:** [English](README.md) | [Português](README.pt-BR.md) | [Español](README.es.md)

## Instalación

```bash
luarocks install daviluaxml
```

## Uso Básico

```lua
-- Registrar el loader para archivos .dslx
require("DaviLuaXML")

-- Ahora puedes usar require() con archivos .dslx
local App = require("mi_componente")
```

### Ejemplo de archivo .dslx

```lua
-- componente.dslx
local function Boton(props, children)
    return string.format('<button class="%s">%s</button>', 
        props.class, 
        children[1]
    )
end

local function App()
    return <div class="container">
        <h1>¡Hola Mundo!</h1>
        <Boton class="primary">Haz clic aquí</Boton>
    </div>
end

return App
```

## Cómo Funciona

DaviLuaXML transforma etiquetas XML en llamadas de función Lua:

```lua
-- Esto:
local el = <div class="container">Hola</div>

-- Se convierte en:
local el = div({class = "container"}, {"Hola"})
```

La función recibe dos argumentos:

- `props` - tabla con los atributos
- `children` - tabla con los hijos (texto, números u otros elementos)

## Sintaxis XML

### Etiquetas simples

```lua
<div/>                          -- Etiqueta self-closing
<p>texto</p>                    -- Etiqueta con contenido
```

### Atributos

```lua
<btn class="primary"/>          -- String
<input value={variable}/>       -- Expresión Lua
<comp enabled/>                 -- Booleano (true)
```

### Expresiones entre llaves

```lua
<suma>{1}{2}{3}</suma>          -- Múltiples valores
<p>{nombre .. " " .. apellido}</p>  -- Expresiones Lua
```

### Etiquetas anidadas

```lua
<div>
    <span>texto</span>
    <ul>
        <li>elemento 1</li>
        <li>elemento 2</li>
    </ul>
</div>
```

### Etiquetas con punto (namespaces)

```lua
<html.div class="x"/>           -- Se convierte en: html.div({class = "x"}, {})
```

## API

### require("DaviLuaXML")

Registra el loader para archivos `.dslx`. Después de esto, `require()` funciona con archivos `.dslx`.

### require("DaviLuaXML.core")

```lua
local lx = require("DaviLuaXML.core")
local resultado, error = lx("archivo.dslx")
```

Ejecuta directamente un archivo `.dslx` por su ruta.

### require("DaviLuaXML.help")

```lua
local help = require("DaviLuaXML.help")
help()              -- Ayuda general
help("sintaxis")    -- Tema específico
help.list()         -- Listar temas
help.lang("es")     -- Definir idioma (en, pt, es)
```

## Logging (Debug)

DaviLuaXML usa [loglua](https://github.com/pessoa736/loglua) para logging. Los logs de debug están en la sección `XMLRuntime`:

```lua
require("DaviLuaXML")
require("mi_modulo")

-- Ver logs de debug del runtime
log.show("XMLRuntime")
```

## Módulos

| Módulo | Descripción |
|--------|-------------|
| `init` | Registra el searcher para require() |
| `core` | Ejecuta archivos .dslx directamente |
| `parser` | Hace parsing de etiquetas XML |
| `transform` | Transforma XML en Lua |
| `elements` | Crea elementos (tablas) |
| `props` | Procesa atributos |
| `errors` | Formateo de errores |
| `help` | Sistema de ayuda |

## Tests

```bash
lua DaviLuaXML/test/run_all.lua
```

## Dependencias

- Lua >= 5.4
- [loglua](https://github.com/pessoa736/loglua)

## Licencia

MIT
