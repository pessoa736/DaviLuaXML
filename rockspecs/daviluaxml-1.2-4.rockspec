package = "DaviLuaXML"
version = "1.2-4"
source = {
   url = "git+https://github.com/pessoa736/DaviLuaXML",
   tag = "1.2-4"
}
description = {
   summary = "XML syntax support for Lua - write XML directly in your Lua code",
   detailed = [[
      DaviLuaXML is a library that allows you to use XML syntax inside Lua code.
      XML tags are transformed into Lua function calls, similar to JSX in JavaScript.
      
      This release adds a middleware system for transforming `props` and `children`
      at transformation time. It also includes fixes to ensure local workspace modules
      are preferred during development and testing.

      Changes in 1.2-4:
      - Added middleware documentation to help system (en, pt, es)
      - Updated topic list to include middleware module
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
      ["DaviLuaXML.middleware"] = "DaviLuaXML/middleware.lua",
      ["DaviLuaXML.help"] = "DaviLuaXML/help.lua",
      ["DaviLuaXML.init"] = "DaviLuaXML/init.lua",
      ["DaviLuaXML.parser"] = "DaviLuaXML/parser.lua",
      ["DaviLuaXML.props"] = "DaviLuaXML/props.lua",
      ["DaviLuaXML.readFile"] = "DaviLuaXML/readFile.lua",
      ["DaviLuaXML.tableToString"] = "DaviLuaXML/tableToString.lua",
      ["DaviLuaXML.transform"] = "DaviLuaXML/transform.lua"
   }
}
