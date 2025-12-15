# Davi System Lua XML - VS Code Extension

Syntax highlighting and formatting support for `.dslx` files (DSLX - Lua with XML/JSX-like syntax).

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

- 🧠 **Autocomplete (no native LSP required)**
  - Suggests tags/components found in your current file
  - Suggests tags/components found across the whole workspace (indexing `.lua` and `.dslx`)
  - Suggests XML attributes from `propTypes` tables when available (e.g. `proptypes.register("MyTag", { ... })`)

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
code --install-extension daviluaxml-0.2.0.vsix
```


## Usage

Simply open any `.dslx` file and the extension will automatically activate.

To format a document:

- Use `Shift+Alt+F` (or `Shift+Option+F` on Mac)
- Or right-click and select "Format Document"

### Enable Lua Language Server for .dslx

Optional: to get Lua diagnostics and richer Lua-aware IntelliSense inside `.dslx`, you can associate the files with your Lua extension/LSP.

For Lua Language Server (sumneko/lua), add this to your VS Code `settings.json`:

```json
"Lua.file.associations": ["*.dslx", "*.lua"]
```

If you use a workspace library:

```json
"Lua.workspace.library": [
  "${workspaceFolder}"
],
"Lua.runtime.fileExtension": ["lua", "dslx"]
```

This is optional; the extension already provides tag + attribute completions without an LSP.

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `daviluaxml.indentSize` | `2` | Number of spaces for indentation |
| `daviluaxml.useTabs` | `false` | Use tabs instead of spaces |
| `daviluaxml.enableTagSuggestions` | `true` | Enable tag/component suggestions (workspace indexing) |
| `daviluaxml.enableVariableSuggestions` | `true` | Enable Lua variable suggestions |

## License

MIT - See [LICENSE](./LICENSE)
