--[[
    Testes do módulo functionCallToStringTransformer.lua (fcst)
]]

-- Carrega a versão local do módulo para garantir que os testes usem
-- a implementação do workspace (evita carregar uma cópia instalada globalmente).
local fcst = dofile("DaviLuaXML/functionCallToStringTransformer.lua")
_G.log = _G.log or require("loglua")
local logTest = log.inSection("tests")

logTest("=== TESTE: functionCallToStringTransformer.lua ===\n")

-- Teste 1: Elemento simples sem props e children
logTest("1. Elemento simples vazio:")
local el1 = {tag = "br", props = {}, children = {}}
local str1 = fcst(el1)
logTest("   entrada: {tag='br', props={}, children={}}")
logTest("   saída:", str1)
assert(str1:find("br%("), "deveria começar com 'br('")
assert(str1:find("%)$"), "deveria terminar com ')'")
logTest("   ✓ OK\n")

-- Teste 2: Elemento com props
logTest("2. Elemento com props:")
local el2 = {tag = "div", props = {class = "container"}, children = {}}
local str2 = fcst(el2)
logTest("   entrada: {tag='div', props={class='container'}, children={}}")
logTest("   saída:", str2)
assert(str2:find("div%("), "deveria começar com 'div('")
assert(str2:find("class"), "deveria conter 'class'")
logTest("   ✓ OK\n")

-- Teste 3: Elemento com children string
logTest("3. Elemento com children string:")
local el3 = {tag = "p", props = {}, children = {"texto aqui"}}
local str3 = fcst(el3)
logTest("   entrada: {tag='p', props={}, children={'texto aqui'}}")
logTest("   saída:", str3)
assert(str3:find("'texto aqui'"), "deveria conter string com aspas")
logTest("   ✓ OK\n")

-- Teste 4: Elemento com children número
logTest("4. Elemento com children número:")
local el4 = {tag = "num", props = {}, children = {42}}
local str4 = fcst(el4)
logTest("   entrada: {tag='num', props={}, children={42}}")
logTest("   saída:", str4)
assert(str4:find("42"), "deveria conter número 42")
logTest("   ✓ OK\n")

-- Teste 5: Elemento com children aninhado
logTest("5. Elemento com children aninhado:")
local el5 = {
    tag = "div", 
    props = {}, 
    children = {
        {tag = "span", props = {}, children = {"inner"}}
    }
}
local str5 = fcst(el5)
logTest("   entrada: div com span aninhado")
logTest("   saída:", str5)
assert(str5:find("div%("), "deveria conter 'div('")
assert(str5:find("span%("), "deveria conter 'span(' aninhado")
logTest("   ✓ OK\n")

-- Teste 6: Elemento com múltiplos children
logTest("6. Elemento com múltiplos children:")
local el6 = {tag = "lista", props = {}, children = {1, 2, 3, "fim"}}
local str6 = fcst(el6)
logTest("   entrada: {tag='lista', props={}, children={1, 2, 3, 'fim'}}")
logTest("   saída:", str6)
assert(str6:find("%[1%]"), "deveria conter índice [1]")
assert(str6:find("%[4%]"), "deveria conter índice [4]")
logTest("   ✓ OK\n")

-- Teste 7: Props nil
logTest("7. Elemento com props nil:")
local el7 = {tag = "vazio", props = nil, children = {}}
local str7 = fcst(el7)
logTest("   entrada: {tag='vazio', props=nil, children={}}")
logTest("   saída:", str7)
assert(str7:find("vazio%("), "deveria funcionar com props nil")
logTest("   ✓ OK\n")

logTest("=== TODOS OS TESTES PASSARAM ===")
log.show("tests")
