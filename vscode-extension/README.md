# DaviLuaXML - VS Code Extension

Syntax highlighting and formatting support for `.lx` files (LuaXML - Lua with XML/JSX-like syntax).

## Features

- ✨ **Syntax Highlighting** - Full color support for:
  - Lua keywords, functions, and operators
  - XML/JSX tags (including namespaced tags like `<html.div>`)
  - XML attributes and values
  - Embedded Lua expressions in attributes `{expression}`
  - Comments and strings

- 📐 **Code Formatting** - Automatic indentation for:
  - Lua control structures (`if`, `function`, `for`, etc.)
  - XML tags (opening/closing)

- ⚙️ **Language Configuration**:
  - Auto-closing brackets and tags
  - Comment toggling (`--` and `--[[ ]]`)
  - Code folding

## Installation

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "DaviLuaXML"
4. Click Install

Or install from VSIX:

```bash
code --install-extension daviluaxml-0.1.0.vsix
```

## Usage

Simply open any `.lx` file and the extension will automatically activate.

To format a document:

- Use `Shift+Alt+F` (or `Shift+Option+F` on Mac)
- Or right-click and select "Format Document"

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `daviluaxml.indentSize` | `2` | Number of spaces for indentation |
| `daviluaxml.useTabs` | `false` | Use tabs instead of spaces |

## License

MIT - See [LICENSE](./LICENSE)
