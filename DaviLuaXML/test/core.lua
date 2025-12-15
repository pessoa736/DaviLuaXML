--[[
    Testes do módulo core.lua
]]
---@diagnostic disable: need-check-nil, undefined-field

_G.log = _G.log or require("loglua")
local logTest = log.inSection("tests")

logTest("=== TESTE: core.lua ===\n")

local core = require("DaviLuaXML.core")

-- Criar arquivo temporário para testes
local function createTempFile(content)
    local path = "/tmp/luaxml_test_" .. os.time() .. ".dslx"
    local f = io.open(path, "w")
    f:write(content)
    f:close()
    return path
end

local function removeTempFile(path)
    os.remove(path)
end

-- Teste 1: Executar arquivo válido
logTest("1. Executar arquivo válido:")
local path1 = createTempFile([[
_G.teste_resultado = "sucesso"
]])
local result1, err1 = core(path1)
logTest("   resultado:", _G.teste_resultado)
assert(_G.teste_resultado == "sucesso", "deveria executar código")
assert(err1 == nil, "não deveria ter erro")
removeTempFile(path1)
logTest("   ✓ OK\n")

-- Teste 2: Executar arquivo com XML
logTest("2. Executar arquivo com XML:")
local path2 = createTempFile([[
local function comp(props, children)
    return props.valor * 2
end
_G.teste_xml = <comp valor={21}/>
]])
local result2, err2 = core(path2)
logTest("   resultado:", _G.teste_xml)
assert(_G.teste_xml == 42, "deveria executar XML e calcular 42")
assert(err2 == nil, "não deveria ter erro")
removeTempFile(path2)
logTest("   ✓ OK\n")

-- Teste 3: Arquivo inexistente
logTest("3. Arquivo inexistente:")
local result3, err3 = core("/tmp/arquivo_que_nao_existe_xyz.dslx")
logTest("   erro:", err3 and err3:sub(1, 50) .. "..." or "nenhum")
assert(result3 == nil, "deveria retornar nil")
assert(err3 ~= nil, "deveria ter mensagem de erro")
logTest("   ✓ OK\n")

-- Teste 4: Erro de sintaxe Lua
logTest("4. Erro de sintaxe Lua:")
local path4 = createTempFile([[
local x = 
]])
local result4, err4 = core(path4)
logTest("   erro:", err4 and err4:sub(1, 60) .. "..." or "nenhum")
assert(result4 == nil, "deveria retornar nil")
assert(err4 ~= nil, "deveria ter mensagem de erro de compilação")
assert(err4:find("compilar") or err4:find("DaviLuaXML"), "deveria ser erro formatado")
removeTempFile(path4)
logTest("   ✓ OK\n")

-- Teste 5: Erro de runtime
logTest("5. Erro de runtime:")
local path5 = createTempFile([[
error("erro proposital")
]])
local result5, err5 = core(path5)
logTest("   erro:", err5 and err5:sub(1, 60) .. "..." or "nenhum")
assert(result5 == nil, "deveria retornar nil")
assert(err5 ~= nil, "deveria ter mensagem de erro")
assert(err5:find("executar") or err5:find("erro proposital"), "deveria indicar erro de execução")
removeTempFile(path5)
logTest("   ✓ OK\n")

-- Teste 6: Retorna código transformado
logTest("6. Retorna código transformado:")
local path6 = createTempFile([[
local function noop() end
<noop/>
]])
local result6, err6 = core(path6)
logTest("   transformado:", result6 and result6:gsub("\n", "\\n"):sub(1, 60) .. "..." or "nil")
assert(result6 ~= nil, "deveria retornar código transformado")
assert(result6:find("noop%("), "código deveria ter 'noop(' transformado")
removeTempFile(path6)
logTest("   ✓ OK\n")

logTest("=== TODOS OS TESTES PASSARAM ===")
log.show("tests")
