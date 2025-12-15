--[[
    Testes do módulo treeshake.lua
]]

_G.log = _G.log or require("loglua")
local logTest = log.inSection("treeshake")

logTest("=== TESTE: treeshake.lua ===")

local treeshake = require("DaviLuaXML.treeshake")

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

test("comments out unused requires", function()
    local code = [[
local unused = require("x")
local used = require("y")
print(used)
]]

    local out = treeshake.apply(code)
    assert(out:find("%-%- %[%s*treeshake%]"), "deveria comentar require não usado")
    assert(out:find("print%(used%)"), "deveria manter uso")
    assert(not out:find("%-%- %[%s*treeshake%]%s*local used"), "não deveria comentar require usado")
end)

logTest("")
logTest(string.format("=== RESULTADO: %d passou, %d falhou ===", passed, failed))

return {
    passed = passed,
    failed = failed
}
