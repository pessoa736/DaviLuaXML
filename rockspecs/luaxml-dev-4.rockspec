package = "luaXML"
version = "dev-4"
source = {
   url = "git+https://github.com/pessoa736/luaXML"
}
description = {
   summary = "XML executor in Lua",
   detailed = "dev",
   homepage = "https://github.com/pessoa736/luaXML",
   license = "MIT"
}
dependencies = {
   "lua >= 5.4",
   "loglua"
}
build = {
   type = "builtin",
   modules = {
      ["luaXML.core"] = "luaXML/core.lua",
      ["luaXML.init"] = "luaXML/init.lua",
      ["luaXML.props"] = "luaXML/props.lua",
      ["luaXML.readFile"] = "luaXML/readFile.lua",
      ["luaXML.props"] = "luaXML/props.lua",
      ["luaXML.parser"] = "luaXML/parser.lua",
   }
}
