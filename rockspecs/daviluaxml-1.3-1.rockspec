package = "DaviLuaXML"
version = "1.3-1"
source = {
   url = "git+https://github.com/pessoa736/DaviLuaXML",
   tag = "1.3-1"
}
description = {
   summary = "Davi System Lua XML - write XML directly in your Lua code",
   detailed = [[
      Davi System Lua XML (DaviLuaXML) is a library that allows you to use XML syntax inside Lua code.
      XML tags are transformed into Lua function calls, similar to JSX in JavaScript.

      Changes in 1.3-1:
      - Renamed file extension from .lx to .dslx (Davi System Lua XML)
      - Updated all documentation and examples
      - VS Code extension updated for .dslx files
   ]],
   homepage = "https://github.com/pessoa736/DaviLuaXML",
   license = "MIT"
}
dependencies = {
   "lua >= 5.4",
   "loglua"
}
build = {
   type = "builtin",
   modules = {
      ["DaviLuaXML"] = "DaviLuaXML/init.lua",
      ["DaviLuaXML.core"] = "DaviLuaXML/core.lua",
      ["DaviLuaXML.elements"] = "DaviLuaXML/elements.lua",
      ["DaviLuaXML.errors"] = "DaviLuaXML/errors.lua",
      ["DaviLuaXML.help"] = "DaviLuaXML/help.lua",
      ["DaviLuaXML.parser"] = "DaviLuaXML/parser.lua",
      ["DaviLuaXML.props"] = "DaviLuaXML/props.lua",
      ["DaviLuaXML.readFile"] = "DaviLuaXML/readFile.lua",
      ["DaviLuaXML.tableToString"] = "DaviLuaXML/tableToString.lua",
      ["DaviLuaXML.transform"] = "DaviLuaXML/transform.lua",
      ["DaviLuaXML.middleware"] = "DaviLuaXML/middleware.lua",
      ["DaviLuaXML.functionCallToStringTransformer"] = "DaviLuaXML/functionCallToStringTransformer.lua",
   }
}
