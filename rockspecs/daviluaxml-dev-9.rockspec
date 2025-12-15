package = "DaviLuaXML"
version = "dev-9"
source = {
   url = "git+https://github.com/pessoa736/DaviLuaXML"
}
description = {
   summary = "Davi System Lua XML - write XML directly in your Lua code",
   detailed = [[
      Davi System Lua XML (DaviLuaXML) is a library that allows you to use XML syntax inside Lua code.
      XML tags are transformed into Lua function calls, similar to JSX in JavaScript.
      
      Features:
      - Write XML directly in .dslx files
      - Automatic transformation to Lua function calls
      - Custom require() loader for .dslx files
      - Support for nested tags, expressions, and attributes
      - Built-in help system
   ]],
   homepage = "https://github.com/pessoa736/DaviLuaXML",
   license = "MIT"
}
dependencies = {
   "lua >= 5.4"
}
build = {
   type = "builtin",
   modules = {
      ["DaviLuaXML"] = "DaviLuaXML/init.lua",
      ["DaviLuaXML.core"] = "DaviLuaXML/core.lua",
      ["DaviLuaXML.elements"] = "DaviLuaXML/elements.lua",
      ["DaviLuaXML.errors"] = "DaviLuaXML/errors.lua",
      ["DaviLuaXML.functionCallToStringTransformer"] = "DaviLuaXML/functionCallToStringTransformer.lua",
      ["DaviLuaXML.help"] = "DaviLuaXML/help.lua",
      ["DaviLuaXML.init"] = "DaviLuaXML/init.lua",
      ["DaviLuaXML.parser"] = "DaviLuaXML/parser.lua",
      ["DaviLuaXML.props"] = "DaviLuaXML/props.lua",
      ["DaviLuaXML.readFile"] = "DaviLuaXML/readFile.lua",
      ["DaviLuaXML.tableToString"] = "DaviLuaXML/tableToString.lua",
      ["DaviLuaXML.transform"] = "DaviLuaXML/transform.lua"
   }
}
