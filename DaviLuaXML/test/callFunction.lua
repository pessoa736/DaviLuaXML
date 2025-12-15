--[[
    Testes integrados de criação de elementos e conversão para função
    
    Testa o fluxo completo: elements.createElement -> functionCallToStringTransformer
]]

_G.log = _G.log or require("loglua")
local logTest = log.inSection("tests")

logTest("=== TESTE: callFunction.lua (integração) ===\n")

local fcst = require("DaviLuaXML.functionCallToStringTransformer")
local elements = require("DaviLuaXML.elements")

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

-- Teste 1: Elemento simples
test("Elemento simples", function()
    local el = elements:createElement("div", {}, {})
    local result = fcst(el)
    assert(result:find("__daviluaxml_invoke%("), "deveria conter wrapper")
    assert(result:find("div"), "deveria conter 'div'")
    logTest("   saída:", result)
end)

-- Teste 2: Elemento com props
test("Elemento com props", function()
    local el = elements:createElement("button", { id = "btn1" }, {})
    local result = fcst(el)
    assert(result:find("button"), "deveria conter 'button'")
    assert(result:find("id"), "deveria conter 'id'")
    logTest("   saída:", result)
end)

-- Teste 3: Elemento com children string
test("Elemento com children string", function()
    local el = elements:createElement("p", {}, {"texto"})
    local result = fcst(el)
    assert(result:find("'texto'"), "deveria conter 'texto'")
    logTest("   saída:", result)
end)

-- Teste 4: Elemento aninhado
test("Elemento aninhado", function()
    local inner = elements:createElement("span", {}, {"inner"})
    local outer = elements:createElement("div", {}, {inner})
    local result = fcst(outer)
    assert(result:find("div"), "deveria conter 'div'")
    assert(result:find("span"), "deveria conter 'span'")
    logTest("   saída:", result)
end)

-- Teste 5: Props complexos
test("Props complexos", function()
    local el = elements:createElement("test", {
        istest = true,
        count = 42
    }, {})
    local result = fcst(el)
    assert(result:find("istest"), "deveria conter 'istest'")
    assert(result:find("42") or result:find("count"), "deveria conter count ou 42")
    logTest("   saída:", result)
end)

-- Teste 6: Múltiplos níveis de aninhamento
test("Múltiplos níveis de aninhamento", function()
    local level3 = elements:createElement("level3", {}, {"deep"})
    local level2 = elements:createElement("level2", {}, {level3})
    local level1 = elements:createElement("level1", {}, {level2})
    local result = fcst(level1)
    assert(result:find("level1"), "deveria conter 'level1'")
    assert(result:find("level2"), "deveria conter 'level2'")
    assert(result:find("level3"), "deveria conter 'level3'")
    logTest("   saída:", result)
end)

-- Teste 7: Múltiplos children
test("Múltiplos children", function()
    local child1 = elements:createElement("li", {}, {"item1"})
    local child2 = elements:createElement("li", {}, {"item2"})
    local ul = elements:createElement("ul", {}, {child1, child2})
    local result = fcst(ul)
    assert(result:find("ul"), "deveria conter 'ul'")
    local _, count = result:gsub("li,", "")
    assert(count == 2, "deveria ter 2 ocorrências de 'li,'")
    logTest("   saída:", result)
end)

-- Teste 8: Props nil
test("Props nil tratado como tabela vazia", function()
    local el = elements:createElement("empty", nil, {})
    local result = fcst(el)
    assert(result:find("empty"), "deveria conter 'empty'")
    logTest("   saída:", result)
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