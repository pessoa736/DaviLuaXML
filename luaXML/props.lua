local M = {}

local insert = table.insert
local concat = table.concat
local format = table.format

function M.tableToPropsString(props)
    if not props then return "" end
    local parts = {}
    for k, v in pairs(props) do
        local t = type(v)
        if t == "string" then
            insert(parts, format('%s="%s"', k, v))
        elseif t == "number" then
            insert(parts, format('%s="%s"', k, tostring(v)))
        elseif t == "boolean" then
            insert(parts, format('%s="%s"', k, v and "true" or "false"))
        elseif t == "table" then
            insert(parts, format('%s="%s"', k, tostring(v)))
        end
    end
    return concat(parts, " ")
end

function M.stringToPropsTable(str)
    if not str or str == "" then return {} end
    local props = {}
    for key, value in string.gmatch(str, '(%w+)%s*=%s*"([^"]*)"') do
        if value == "true" then
            props[key] = true
        elseif value == "false" then
            props[key] = false
        elseif tonumber(value) then
            props[key] = tonumber(value)
        else
            props[key] = value
        end
    end
    return props
end

return M
