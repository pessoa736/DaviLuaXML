--[[
    DaviLuaXML Runtime
    ==================

    Helpers usados pelo código transformado.

    Atualmente:
      - invoke(callableExpr, tagName, props, children):
          chama o componente/tag e (opcionalmente) valida props.

    O código gerado pelo transformer chama `__daviluaxml_invoke(...)`.
--]]

local proptypes = require("DaviLuaXML.proptypes")

local M = {}

local function resolveSchema(callable, tagName)
    if type(callable) == "table" and type(callable.propTypes) == "table" then
        return callable.propTypes
    end
    return proptypes.registry[tagName]
end

--- Invoca uma tag/componente.
--- @param callable any Função ou tabela chamável (metatable __call)
--- @param tagName string Nome textual da tag (ex: "Button" ou "ui.Button")
--- @param props table|nil
--- @param children table|nil
--- @param ctx table|nil { filename, line }
function M.invoke(callable, tagName, props, children, ctx)
    local schema = resolveSchema(callable, tagName)
    if schema then
        local ok, err = proptypes.validate(props, schema, {
            tagName = tagName,
            filename = ctx and ctx.filename or nil,
            line = ctx and ctx.line or nil,
        })
        if not ok then
            error(err, 0)
        end
    end

    if type(callable) == "function" then
        return callable(props or {}, children or {})
    end

    if type(callable) == "table" then
        local mt = getmetatable(callable)
        if mt and type(mt.__call) == "function" then
            return callable(props or {}, children or {})
        end
        if type(callable.render) == "function" then
            return callable.render(props or {}, children or {})
        end
    end

    error(string.format("[DaviLuaXML] tag '%s' is not callable", tostring(tagName)), 0)
end

return M
