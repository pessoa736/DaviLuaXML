--[[
    Testes do módulo errors.lua
]]


_G.log = _G.log or require("loglua")
local logTest = log.inSection("errors")

local errors = require("DaviLuaXML.errors")

logTest("=== TESTE: errors.lua ===")

-- Teste 1: getLineInfo
logTest("1. Teste getLineInfo:")
local code = "linha1\nlinha2\nlinha3"
local line, col = errors.getLineInfo(code, 10) -- posição na linha 2
logTest("   código:", code:gsub("\n", "\\n"))
logTest("   posição 10 -> linha:", line, "coluna:", col)
assert(line == 2, "deveria ser linha 2")
logTest("   ✓ OK")

-- Teste 2: getLine
logTest("2. Teste getLine:")
local linha2 = errors.getLine(code, 2)
logTest("   linha 2:", linha2)
assert(linha2 == "linha2", "deveria retornar 'linha2'")
logTest("   ✓ OK")

-- Teste 3: format básico
logTest("3. Teste format básico:")
local msg = errors.format("erro de teste")
logTest("   mensagem:", msg)
assert(msg:find("%[DaviLuaXML%]"), "deveria conter [DaviLuaXML]")
logTest("   ✓ OK")

-- Teste 4: format com arquivo
logTest("4. Teste format com arquivo:")
local msg2 = errors.format("erro de teste", nil, nil, "arquivo.dslx")
logTest("   mensagem:", msg2)
assert(msg2:find("arquivo.dslx"), "deveria conter nome do arquivo")
logTest("   ✓ OK")

-- Teste 5: format com posição
logTest("5. Teste format com código e posição:")
local codigo = "local x = <tag>\nconteudo\n</tag>"
local msg3 = errors.format("tag inválida", codigo, 11, "teste.dslx")
logTest("   mensagem:", msg3)
assert(msg3:find("linha"), "deveria conter 'linha'")
logTest("   ✓ OK")

-- Teste 6: unclosedTag
logTest("6. Teste unclosedTag:")
local msg4 = errors.unclosedTag("div", codigo, 11, "teste.dslx")
logTest("   mensagem:", msg4)
assert(msg4:find("div"), "deveria conter nome da tag")
assert(msg4:find("</div>"), "deveria sugerir fechamento")
logTest("   ✓ OK")

-- Teste 7: invalidTag
logTest("7. Teste invalidTag:")
local msg5 = errors.invalidTag(codigo, 1, "teste.dslx")
logTest("   mensagem:", msg5)
assert(msg5:find("inválida") or msg5:find("malformada"), "deveria indicar tag inválida")
logTest("   ✓ OK")

-- Teste 8: compilationError
logTest("8. Teste compilationError:")
local msg6 = errors.compilationError("unexpected symbol", "teste.dslx")
logTest("   mensagem:", msg6)
assert(msg6:find("compilar"), "deveria mencionar compilação")
logTest("   ✓ OK")

-- Teste 9: runtimeError
logTest("9. Teste runtimeError:")
local msg7 = errors.runtimeError("nil value", "teste.dslx")
logTest("   mensagem:", msg7)
assert(msg7:find("executar"), "deveria mencionar execução")
logTest("   ✓ OK")

logTest("=== TODOS OS TESTES PASSARAM ===")
log.show()
