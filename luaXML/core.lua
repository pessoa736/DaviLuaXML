local readFile = require("luaXML.readFile")
local transform = require("luaXML.transform").transform

return function(file)
    local code = readFile(file)
    local transformed = transform(code)

    local chunk, loadErr = load(transformed, "@"..file)
    if not chunk then
        return nil, "Erro ao compilar código transformado: " .. tostring(loadErr)
    end
    local ok, runErr = pcall(chunk)
    if not ok then
        return nil, "Erro ao executar código transformado: " .. tostring(runErr)
    end

    return transformed
end