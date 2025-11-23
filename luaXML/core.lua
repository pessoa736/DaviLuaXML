local parser = require("luaXML.parser")
local readFile = require("luaXML.readFile")

return function(file)
    local code = readFile(file)
    local elements, posI, posF = parser(code)

    local p1 = code:sub(0, posI)
    local p2 = code:sub(posF, #code)

end