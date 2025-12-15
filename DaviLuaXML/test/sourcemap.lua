--[[
    Testes do módulo sourcemap
]]

_G.log = _G.log or require("loglua")
local logTest = log.inSection("sourcemap")

logTest("=== TESTE: sourcemap.lua ===")

local transform = dofile("DaviLuaXML/transform.lua").transform
local sourcemap = require("DaviLuaXML.sourcemap")

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

test("rewrite runtime error line", function()
    local filename = "/tmp/daviluaxml_sourcemap_test.dslx"

    local code = [[
local x = <div>
  <span/>
</div>
error("boom")
]]

    local out, err, map = transform(code, filename)
    assert(out and not err, "transform deveria ter sucesso")

    local chunk = assert(load(out, "@" .. filename))

    local ok, runErr = xpcall(chunk, function(e)
        return sourcemap.rewriteError(tostring(e), map)
    end)

    assert(not ok, "deveria falhar com erro")
    assert(tostring(runErr):find(filename .. ":4:"), "deveria apontar para linha 4 do .dslx")
end)

logTest("")
logTest(string.format("=== RESULTADO: %d passou, %d falhou ===", passed, failed))

return {
    passed = passed,
    failed = failed
}
