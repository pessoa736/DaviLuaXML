
local middleware = require("DaviLuaXML.middleware")

--- Serializa uma string de forma segura para Lua.
--- Usa [[ ]] para strings multilinha, aspas simples para strings simples.
local function serializeString(s)
    s = tostring(s)
    if s:find("\n") then
        -- String multilinha: usar [[ ]] com nível adequado
        local level = 0
        while s:find("%]" .. string.rep("=", level) .. "%]") do
            level = level + 1
        end
        local eq = string.rep("=", level)
        return "[" .. eq .. "[" .. s .. "]" .. eq .. "]"
    else
        -- String simples: usar aspas simples com escape
        return "'" .. s:gsub("\\", "\\\\"):gsub("'", "\\'") .. "'"
    end
end

local function serializePropValue(v)
    if type(v) == "table" and v.__luaexpr then
        return v.code
    elseif type(v) == "string" then
        return serializeString(v)
    elseif type(v) == "number" or type(v) == "boolean" then
        return tostring(v)
    elseif type(v) == "table" then
        local parts = {}
        for k, val in pairs(v) do
            local key = type(k) == "string" and k or ("[" .. k .. "]")
            table.insert(parts, key .. " = " .. serializePropValue(val))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return tostring(v)
    end
end

local fcst

local function serializeChild(ch)
    if type(ch) == "table" and ch.__luaexpr then
        return ch.code
    elseif type(ch) == "table" and ch.tag then
        return fcst(ch)
    elseif type(ch) == "string" then
        return serializeString(ch)
    else
        return tostring(ch)
    end
end

local function propsToString(props, element)
    if not props or next(props) == nil then return "{}" end
    local parts = {}
    for k, v in pairs(props) do
        local key = tostring(k)
        local ctx = { key = k, tag = (element and (element.tag or element.name)), props = props }
        local newv = middleware.runProp(v, ctx)
        table.insert(parts, key .. " = " .. serializePropValue(newv))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function childrenToString(children, element)
    if not children or #children == 0 then return "{}" end
    local parts = {}
    for i = 1, #children do
        local ctx = { index = i, tag = (element and (element.tag or element.name)), parent = element }
        local newch = middleware.runChild(children[i], ctx)
        local val = serializeChild(newch)
        table.insert(parts, "[" .. i .. "] = " .. val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

fcst = function(element)
    local tag = element.tag or element.name or "unknown"
    local props = element.props or element.attrs or {}
    local children = element.children or {}

    local propsStr = propsToString(props, element)
    local childrenStr = childrenToString(children, element)

    return "__daviluaxml_invoke(" .. tag .. ", " .. serializeString(tag) .. ", " .. propsStr .. ", " .. childrenStr .. ")"
end

return fcst


