package = "luaXML"
version = "dev-1"

source = {
   url = "git+https://github.com/pessoa736/VectorAndMatrixSystemLua"
}

description = {

   summary = "XML executor in Lua",
   detailed = "dev",
   homepage = "https://github.com/pessoa736/VectorAndMatrixSystemLua",
   license = "MIT"

}
dependencies = {
   "lua >= 5.4"
}

build = {
   type = "builtin",
   modules = {
      ["luaXML.core"] = "luaXML/core.lua",
      ["luaXML.init"] = "luaXML/init.lua",
      ["luaXML.parser"] = "luaXML/parser.lua",
   }
}

