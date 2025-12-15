--[[
    Testes do módulo transform.lua
]]
---@diagnostic disable: need-check-nil

-- Carrega o transform do workspace diretamente para evitar conflito com uma
-- possível versão instalada globalmente.
local transform = dofile("DaviLuaXML/transform.lua").transform
_G.log = _G.log or require("loglua")
local logTest = log.inSection("tests")

logTest("=== TESTE: transform.lua ===\n")

-- Teste 1: Tag self-closing simples
logTest("1. Tag self-closing simples:")
local code1 = "<teste/>"
local result1 = transform(code1)
logTest("   entrada:", code1)
logTest("   saída:", result1)
assert(result1:find("__daviluaxml_invoke%("), "deveria conter '__daviluaxml_invoke('")
assert(result1:find("teste"), "deveria conter nome da tag")
logTest("   ✓ OK\n")

-- Teste 2: Tag com atributos
logTest("2. Tag com atributos:")
local code2 = '<btn class="primary"/>'
local result2 = transform(code2)
logTest("   entrada:", code2)
logTest("   saída:", result2)
assert(result2:find("class"), "deveria conter atributo 'class'")
assert(result2:find("primary"), "deveria conter valor 'primary'")
logTest("   ✓ OK\n")

-- Teste 3: Tag com conteúdo texto
logTest("3. Tag com conteúdo texto:")
local code3 = "<p>ola mundo</p>"
local result3 = transform(code3)
logTest("   entrada:", code3)
logTest("   saída:", result3)
assert(result3:find("p"), "deveria conter nome da tag")
assert(result3:find("ola mundo"), "deveria conter texto")
logTest("   ✓ OK\n")

-- Teste 4: Tag com expressão em chaves
logTest("4. Tag com expressão em chaves:")
local code4 = "<soma>{1}{2}{3}</soma>"
local result4 = transform(code4)
logTest("   entrada:", code4)
logTest("   saída:", result4)
assert(result4:find("1"), "deveria conter valor 1")
assert(result4:find("2"), "deveria conter valor 2")
assert(result4:find("3"), "deveria conter valor 3")
logTest("   ✓ OK\n")

-- Teste 5: Tags aninhadas
logTest("5. Tags aninhadas:")
local code5 = "<div><span>texto</span></div>"
local result5 = transform(code5)
logTest("   entrada:", code5)
logTest("   saída:", result5)
assert(result5:find("div"), "deveria conter 'div'")
assert(result5:find("span"), "deveria conter 'span'")
logTest("   ✓ OK\n")

-- Teste 6: Código misto (Lua + XML)
logTest("6. Código misto (Lua + XML):")
local code6 = "local x = 1\n<tag/>\nprint(x)"
local result6 = transform(code6)
logTest("   entrada:", code6:gsub("\n", "\\n"))
logTest("   saída:", result6:gsub("\n", "\\n"))
assert(result6:find("local x = 1"), "deveria manter código Lua")
assert(result6:find("tag"), "deveria transformar tag")
assert(result6:find("print%(x%)"), "deveria manter print")
logTest("   ✓ OK\n")

-- Teste 7: Ignorar tags reservadas Lua
logTest("7. Ignorar tags reservadas Lua (<const>, <close>):")
local code7 = "local x <const> = 10"
local result7 = transform(code7)
logTest("   entrada:", code7)
logTest("   saída:", result7)
assert(result7 == code7, "deveria manter código inalterado")
logTest("   ✓ OK\n")

-- Teste 8: Tag com nome contendo ponto
logTest("8. Tag com nome contendo ponto:")
local code8 = '<html.div class="x"/>'
local result8 = transform(code8)
logTest("   entrada:", code8)
logTest("   saída:", result8)
assert(result8:find("html%.div"), "deveria conter 'html.div'")
logTest("   ✓ OK\n")

-- Teste 9: Atributo com expressão
logTest("9. Atributo com expressão Lua:")
local code9 = "<comp valor={10 + 5}/>"
local result9 = transform(code9)
logTest("   entrada:", code9)
logTest("   saída:", result9)
assert(result9:find("valor"), "deveria conter atributo 'valor'")
logTest("   ✓ OK\n")

logTest("=== TODOS OS TESTES PASSARAM ===")
log.show("tests")
