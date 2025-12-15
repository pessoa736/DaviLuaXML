--[[
    DaviLuaXML PropTypes
    ====================

    Validação simples de props em runtime.

    Objetivo: ser leve e opcional, sem depender de ferramentas externas.

    USO (registry):
      local t = require("DaviLuaXML.proptypes")
      t.register("Button", {
        label = t.string({ required = true }),
        disabled = t.boolean(),
        variant = t.oneOf({"primary", "secondary"}),
      })

    USO (no componente):
      local Button = setmetatable({
        propTypes = { label = t.string({ required = true }) }
      }, {
        __call = function(self, props, children) ... end
      })

    O runtime usa esses schemas via `DaviLuaXML.runtime.invoke`.
--]]

local M = {}

M.enabled = true
M.registry = {}

local function typename(v)
    local t = type(v)
    if t ~= "table" then
        return t
    end
    local mt = getmetatable(v)
    if mt and mt.__name then
        return mt.__name
    end
    return "table"
end

local function errPrefix(ctx)
    if not ctx then
        return "[PropTypes]"
    end
    local where = ctx.tagName and ("<" .. ctx.tagName .. ">") or "<unknown>"
    local file = ctx.filename and (" " .. ctx.filename) or ""
    local line = ctx.line and (":" .. tostring(ctx.line)) or ""
    return string.format("[PropTypes] %s%s%s", where, file, line)
end

local function makeValidator(kind, opts)
    opts = opts or {}
    return {
        __kind = kind,
        required = opts.required == true,
        allowNil = opts.allowNil == true,
        message = opts.message,
        _opts = opts,
    }
end

function M.required(v)
    if type(v) == "table" then
        v.required = true
        return v
    end
    return makeValidator("custom", { required = true, fn = v })
end

function M.string(opts) return makeValidator("string", opts) end
function M.number(opts) return makeValidator("number", opts) end
function M.boolean(opts) return makeValidator("boolean", opts) end
function M.func(opts) return makeValidator("function", opts) end
function M.table(opts) return makeValidator("table", opts) end
function M.any(opts) return makeValidator("any", opts) end

function M.oneOf(values, opts)
    opts = opts or {}
    opts.values = values
    return makeValidator("oneOf", opts)
end

function M.arrayOf(validator, opts)
    opts = opts or {}
    opts.of = validator
    return makeValidator("arrayOf", opts)
end

function M.shape(schema, opts)
    opts = opts or {}
    opts.schema = schema
    return makeValidator("shape", opts)
end

function M.register(tagName, schema)
    M.registry[tagName] = schema
end

local function isArray(t)
    if type(t) ~= "table" then
        return false
    end
    local n = 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" then
            return false
        end
        if k > n then n = k end
    end
    return n == #t
end

local function validateValue(key, value, validator, ctx)
    if type(validator) == "function" then
        local ok, msg = validator(value, ctx)
        if ok == false then
            return false, msg or ("invalid value for prop '" .. tostring(key) .. "'")
        end
        return true
    end

    if type(validator) ~= "table" then
        return true
    end

    if value == nil then
        if validator.required and not validator.allowNil then
            return false, "missing required prop '" .. tostring(key) .. "'"
        end
        return true
    end

    local kind = validator.__kind
    if kind == "any" or kind == nil then
        return true
    end

    if kind == "oneOf" then
        local values = validator._opts.values or {}
        for _, allowed in ipairs(values) do
            if value == allowed then
                return true
            end
        end
        return false, "prop '" .. tostring(key) .. "' must be one of: " .. table.concat(values, ", ")
    end

    if kind == "arrayOf" then
        if type(value) ~= "table" or not isArray(value) then
            return false, "prop '" .. tostring(key) .. "' must be an array"
        end
        local inner = validator._opts.of
        for i = 1, #value do
            local ok, msg = validateValue(key .. "[" .. i .. "]", value[i], inner, ctx)
            if not ok then
                return false, msg
            end
        end
        return true
    end

    if kind == "shape" then
        if type(value) ~= "table" then
            return false, "prop '" .. tostring(key) .. "' must be a table"
        end
        local schema = validator._opts.schema or {}
        local ok, msg = M.validate(value, schema, ctx)
        if not ok then
            return false, msg
        end
        return true
    end

    if type(value) ~= kind then
        return false, string.format(
            "prop '%s' expected %s, got %s",
            tostring(key),
            kind,
            typename(value)
        )
    end

    return true
end

--- Valida uma tabela de props contra um schema.
--- @param props table|nil
--- @param schema table|nil
--- @param ctx table|nil { tagName, filename, line }
--- @return boolean ok
--- @return string|nil error
function M.validate(props, schema, ctx)
    if not M.enabled then
        return true
    end
    if schema == nil then
        return true
    end
    if props == nil then
        props = {}
    end
    if type(props) ~= "table" then
        return false, errPrefix(ctx) .. ": props must be a table"
    end

    for key, validator in pairs(schema) do
        local ok, msg = validateValue(key, props[key], validator, ctx)
        if not ok then
            local prefix = errPrefix(ctx)
            if type(msg) == "string" and msg:find("^%[PropTypes%]") then
                return false, msg
            end
            return false, prefix .. ": " .. tostring(msg)
        end
    end

    return true
end

return M
