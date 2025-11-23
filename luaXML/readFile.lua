

local function readFile(dirFile)
    local file <close> = io.open(dirFile, "r+")
    if not file then
        error("não foi possivel abrir o arquivo: ".. dirFile)
    end

    local content = file:read("a")
    return content
end

return readFile