--[[
    DaviLuaXML Sourcemap
    ====================

    Mapeamento simples de linhas para erros em runtime.

    Implementação:
      - O transformer calcula checkpoints de delta de linhas.
      - Para um número de linha no código transformado, aplicamos:
          originalLine = (compiledLine - headerLines) + deltaAt(line)

    Limitação: mapeia com boa precisão linhas *após* substituições.
--]]

local M = {}

local function deltaAt(checkpoints, line)
    local d = 0
    for i = 1, #checkpoints do
        local c = checkpoints[i]
        if line >= c.line then
            d = c.delta
        else
            break
        end
    end
    return d
end

--- Mapeia uma linha do código transformado para o código original.
--- @param map table|nil
--- @param compiledLine number
--- @return number
function M.mapLine(map, compiledLine)
    if not map or type(compiledLine) ~= "number" then
        return compiledLine
    end

    local headerLines = tonumber(map.headerLines or 0) or 0
    local lineNoHeader = compiledLine - headerLines
    if lineNoHeader < 1 then
        lineNoHeader = 1
    end

    local checkpoints = map.checkpoints or {}
    local d = deltaAt(checkpoints, lineNoHeader)
    local orig = lineNoHeader + d
    if orig < 1 then
        orig = 1
    end
    return orig
end

--- Reescreve mensagens de erro/traceback ajustando números de linha.
--- @param err string
--- @param map table|nil
--- @return string
function M.rewriteError(err, map)
    if not map or type(err) ~= "string" then
        return err
    end

    local filename = map.filename
    if not filename then
        return err
    end

    local function repl(prefixAt, file, line, suffix)
        local n = tonumber(line)
        if not n then
            return prefixAt .. file .. ":" .. line .. suffix
        end
        local mapped = M.mapLine(map, n)
        return prefixAt .. file .. ":" .. tostring(mapped) .. suffix
    end

    -- Ajusta ocorrências como: @file:123: ou file:123:
    local out = err:gsub("(@?)" .. filename:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. ":(%d+)(:)" , repl)
    return out
end

return M
