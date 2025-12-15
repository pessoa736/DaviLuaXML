--[[
    Testes de importação de arquivos .dslx via require
    
    Testa a integração completa do loader DaviLuaXML com o sistema require do Lua.
]]


_G.log = _G.log or require("loglua")
local logTest = log.inSection("tests")

logTest("=== TESTE: import_lx.lua ===\n")

local passed = 0
local failed = 0

local function test(name, fn)
    logTest(string.format("%d. %s:", passed + failed + 1, name))
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        logTest("   ✓ OK\n")
    else
        failed = failed + 1
        logTest("   ✗ FALHOU: " .. tostring(err) .. "\n")
    end
end

-- Registrar o loader DaviLuaXML
test("Registrar loader DaviLuaXML", function()
    require("DaviLuaXML")
    -- Se não der erro, passou
    logTest("   loader registrado com sucesso")
end)

-- Teste: Carregar arquivo .dslx via require
test("Carregar arquivo .dslx via require", function()
    -- Limpar cache se existir
    package.loaded["DaviLuaXML.test.dslx.1"] = nil
    
    -- Capturar output do arquivo
    local oldPrint = print
    local outputs = {}
    print = function(...)
        local args = {...}
        table.insert(outputs, table.concat(args, "\t"))
        oldPrint(...)
    end
    
    -- Carregar o arquivo
    require("DaviLuaXML.test.dslx.1")
    
    -- Restaurar print
    print = oldPrint
    
    -- Verificar que executou (deve imprimir algo)
    assert(#outputs > 0, "arquivo deveria produzir output")
end)

-- Teste: Arquivo .dslx pode ser recarregado
test("Recarregar arquivo .dslx", function()
    package.loaded["DaviLuaXML.test.dslx.1"] = nil
    
    local ok1 = pcall(require, "DaviLuaXML.test.dslx.1")
    assert(ok1, "primeira carga deveria funcionar")
    
    -- Segunda chamada deve usar cache
    local ok2 = pcall(require, "DaviLuaXML.test.dslx.1")
    assert(ok2, "segunda carga deveria funcionar (do cache)")
end)

logTest(string.rep("=", 50))
logTest(string.format("Resultado: %d passaram, %d falharam", passed, failed))
logTest(string.rep("=", 50))

if failed > 0 then
    logTest("\n=== ALGUNS TESTES FALHARAM ===")
    log.show("tests")
    os.exit(1)
else
    logTest("\n=== TODOS OS TESTES PASSARAM ===")
    log.show("tests")
end