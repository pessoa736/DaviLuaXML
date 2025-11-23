local parser = require("luaXML.parser")

local test = [[
  <test pr=t>
    <test/>
    <test/>
  </test>
]]

local node, startPos, endPos = parser(test)

print(node)
print(string.format("Tag principal começa em %d e termina em %d", startPos, endPos))