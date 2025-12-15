--[[
    DaviLuaXML Tree-shaking (básico)
    ================================

    Estratégia mínima e segura:
      - Identifica linhas `local X = require("...")`
      - Se o identificador X não aparece em nenhum outro lugar do código,
        comenta a linha.

    Observação: isso é pensado para pré-compilação (compile.lua), não runtime.
--]]

local M = {}

local function escapePattern(s)
    return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

local function countWord(code, word)
    local pat = "%f[%w_]" .. escapePattern(word) .. "%f[^%w_]"
    local n = 0
    code:gsub(pat, function()
        n = n + 1
        return nil
    end)
    return n
end

--- Aplica tree-shaking no código Lua transformado.
--- @param code string
--- @return string
function M.apply(code)
    local lines = {}

    for line in (code .. "\n"):gmatch("(.-)\n") do
        local var = line:match("^%s*local%s+([%a_][%w_]*)%s*=%s*require%s*%(")
        if var then
            -- Conta ocorrências no código inteiro (inclui essa linha)
            local occurrences = countWord(code, var)
            if occurrences <= 1 then
                table.insert(lines, "-- [treeshake] " .. line)
            else
                table.insert(lines, line)
            end
        else
            table.insert(lines, line)
        end
    end

    return table.concat(lines, "\n")
end

return M
