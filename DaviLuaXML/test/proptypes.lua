--[[
    Testes do módulo proptypes/runtime
]]

_G.log = _G.log or require("loglua")
local logTest = log.inSection("proptypes")

logTest("=== TESTE: proptypes.lua ===")

local t = require("DaviLuaXML.proptypes")
local runtime = require("DaviLuaXML.runtime")

local passed = 0
local failed = 0

local function test(name, fn)
    logTest(string.format("%d. %s:", passed + failed + 1, name))
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        logTest("   ✓ OK")
    else
        failed = failed + 1
        log.error("   ✗ FALHOU: " .. tostring(err))
    end
end

test("required string via registry", function()
    t.register("Button", {
        label = t.string({ required = true }),
    })

    local Button = function(props)
        return props.label
    end

    local ok, err = pcall(function()
        runtime.invoke(Button, "Button", {}, {})
    end)

    assert(not ok, "deveria falhar sem label")
    assert(tostring(err):find("missing required prop 'label'"), "mensagem deveria mencionar label")
end)

test("component-local propTypes", function()
    local Comp = setmetatable({
        propTypes = {
            x = t.number({ required = true }),
        }
    }, {
        __call = function(self, props)
            return props.x
        end
    })

    local ok, err = pcall(function()
        runtime.invoke(Comp, "Comp", {}, {})
    end)

    assert(not ok, "deveria falhar sem x")
    assert(tostring(err):find("missing required prop 'x'"), "mensagem deveria mencionar x")
end)

logTest("")
logTest(string.format("=== RESULTADO: %d passou, %d falhou ===", passed, failed))

return {
    passed = passed,
    failed = failed
}
