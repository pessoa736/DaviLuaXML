--[[
    Testes do módulo cache.lua
    
    O cache armazena código transformado para evitar re-transformação.
]]

_G.log = _G.log or require("loglua")
local logTest = log.inSection("cache")

logTest("=== TESTE: cache.lua ===")

local cache = require("DaviLuaXML.cache")

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

-- Teste 1: Cache miss em arquivo inexistente
test("Cache miss em arquivo inexistente", function()
    local result = cache.get("/tmp/nao_existe_xyz.dslx", "conteudo qualquer")
    assert(result == nil, "deveria retornar nil para cache miss")
end)

-- Teste 2: Set e Get
test("Set e Get", function()
    local filepath = "/tmp/test_cache_" .. os.time() .. ".dslx"
    local content = "local x = <div/>"
    local transformed = "local x = __daviluaxml_invoke(div, 'div', {}, {})"
    
    -- Salvar no cache
    cache.set(filepath, content, transformed)
    
    -- Recuperar do cache
    local cached = cache.get(filepath, content)
    assert(cached ~= nil, "deveria retornar código do cache")
    assert(cached:find("__daviluaxml_invoke%("), "código em cache deveria conter wrapper")
end)

-- Teste 3: Cache invalida com conteúdo diferente
test("Cache invalida com conteúdo diferente", function()
    local filepath = "/tmp/test_cache_invalidate_" .. os.time() .. ".dslx"
    local content1 = "local x = <div/>"
    local content2 = "local x = <span/>"  -- Conteúdo diferente
    local transformed = "local x = __daviluaxml_invoke(div, 'div', {}, {})"
    
    -- Salvar no cache com content1
    cache.set(filepath, content1, transformed)
    
    -- Tentar recuperar com content2 (hash diferente) - deveria dar miss
    local cached = cache.get(filepath, content2)
    assert(cached == nil, "deveria retornar nil para conteúdo diferente")
end)

-- Teste 4: Desabilitar cache
test("Desabilitar cache", function()
    local originalEnabled = cache.enabled
    cache.enabled = false
    
    local filepath = "/tmp/test_cache_disabled_" .. os.time() .. ".dslx"
    local content = "local x = <div/>"
    local transformed = "local x = __daviluaxml_invoke(div, 'div', {}, {})"
    
    cache.set(filepath, content, transformed)
    local cached = cache.get(filepath, content)
    
    cache.enabled = originalEnabled
    
    assert(cached == nil, "deveria retornar nil quando cache desabilitado")
end)

-- Teste 5: Estatísticas do cache
test("Estatísticas do cache", function()
    local stats = cache.stats()
    assert(type(stats) == "table", "stats deveria retornar tabela")
    assert(type(stats.files) == "number", "stats.files deveria ser número")
    assert(type(stats.size) == "string", "stats.size deveria ser string")
    assert(type(stats.dir) == "string", "stats.dir deveria ser string")
end)

-- Resumo
logTest("")
logTest(string.format("=== RESULTADO: %d passou, %d falhou ===", passed, failed))

return {
    passed = passed,
    failed = failed
}
