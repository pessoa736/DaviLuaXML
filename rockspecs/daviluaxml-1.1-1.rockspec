package = "DaviLuaXML"
version = "1.1-1"
source = {
   url = "git+https://github.com/pessoa736/DaviLuaXML",
   tag = "1.1-1"
}
description = {
   summary = "XML syntax support for Lua - write XML directly in your Lua code",
   detailed = [[
      DaviLuaXML is a library that allows you to use XML syntax inside Lua code.
      XML tags are transformed into Lua function calls, similar to JSX in JavaScript.
      
      Features:
      - Write XML directly in .dslx files
      - Automatic transformation to Lua function calls
      - Custom require() loader for .dslx files
      - Support for nested tags, expressions, and attributes
      - Multi-language help system (en, pt, es)
      - Debug logging with loglua (XMLRuntime section)
      
      Changes in 1.1-1:
      - Added multi-language support to help module (English, Portuguese, Spanish)
      - Added README files in 3 languages with language selector
      - Fixed test runner to properly configure LUA_PATH for loglua
      - Tests now use log.live() for real-time output
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
      DaviLuaXML = "DaviLuaXML/init.lua",
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
