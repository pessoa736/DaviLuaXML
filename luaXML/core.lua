local parser = require("luaXML.parser")
local readFile = require("luaXML.readFile")
local fcst = require("luaXML.functionCallToStringTransformer")

return function(file)
    local code = readFile(file)
    local pos = 1
    local element, relStart, relEnd, firstTagStart
    while true do
        local s, e, tagName = code:find("<([%w_]+)", pos)
        if not s then
            return nil, "Nenhuma tag válida encontrada"
        end
        -- se for reservado (<const>, <close>) e vier imediatamente '>' então ignorar
        local gtPos = code:find(">", e + 1)
        local immediateClose = (gtPos == e + 1)
        if (tagName == "const" or tagName == "close") and immediateClose then
            pos = e + 1
        else
            local candidate = code:sub(s)
            local candElement, rs, re = parser(candidate)
            if candElement then
                element, relStart, relEnd, firstTagStart = candElement, rs, re, s
                break
            else
                pos = e + 1
            end
        end
    end

    -- localizar abertura real
    local openStart, openEnd, tagName, attrs, selfClosed = code:find("<([%w_]+)%s*(.-)(/?)>", firstTagStart)
    if not openStart then
        return nil, "Falha ao localizar abertura da tag"
    end
    local tagEnd
    if selfClosed == "/" then
        tagEnd = openEnd
    else
        local closeStart, closeEnd = code:find("</" .. tagName .. "%s*>", openEnd + 1)
        if not closeEnd then
            return nil, "Fechamento da tag não encontrado"
        end
        tagEnd = closeEnd
    end

    local callStr = fcst(element)
    local transformed = code:sub(1, openStart - 1) .. callStr .. code:sub(tagEnd + 1)

    local chunk, loadErr = load(transformed, file)
    if not chunk then
        return nil, "Erro ao compilar código transformado: " .. tostring(loadErr)
    end
    local ok, runErr = pcall(chunk)
    if not ok then
        return nil, "Erro ao executar código transformado: " .. tostring(runErr)
    end

    return transformed
end