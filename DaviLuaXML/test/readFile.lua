--[[
    Testes do módulo readFile.lua
    
    O módulo readFile lê o conteúdo de um arquivo e retorna como string.
]]
---@diagnostic disable: need-check-nil

_G.log = _G.log or require("loglua")
local logTest = log.inSection("tests")

logTest("=== TESTE: readFile.lua ===\n")

local readFile = require("DaviLuaXML.readFile")

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

-- Criar arquivo temporário para testes
local function createTempFile(content)
    local path = "/tmp/luaxml_readfile_test_" .. os.time() .. ".txt"
    local f = io.open(path, "w")
    if f then
        f:write(content)
        f:close()
    end
    return path
end

local function removeTempFile(path)
    os.remove(path)
end

-- Teste 1: Ler arquivo existente
test("Ler arquivo existente", function()
    local path = createTempFile("conteudo de teste")
    local content = readFile(path)
    assert(content == "conteudo de teste", "conteúdo deveria ser 'conteudo de teste'")
    removeTempFile(path)
end)

-- Teste 2: Ler arquivo com múltiplas linhas
test("Ler arquivo com múltiplas linhas", function()
    local path = createTempFile("linha1\nlinha2\nlinha3")
    local content = readFile(path)
    assert(content:find("linha1"), "deveria conter linha1")
    assert(content:find("linha2"), "deveria conter linha2")
    assert(content:find("linha3"), "deveria conter linha3")
    removeTempFile(path)
end)

-- Teste 3: Ler arquivo .lx de teste
test("Ler arquivo .lx real", function()
    local content = readFile("DaviLuaXML/test/lx/1.lx")
    assert(content ~= nil, "conteúdo não deveria ser nil")
    assert(#content > 0, "arquivo não deveria estar vazio")
    assert(content:find("soma") or content:find("function"), "deveria conter código Lua")
end)

-- Teste 4: Arquivo inexistente lança erro
test("Arquivo inexistente lança erro", function()
    local ok, err = pcall(function()
        readFile("/tmp/arquivo_que_nao_existe_xyz123.txt")
    end)
    assert(not ok, "arquivo inexistente deveria lançar erro")
    assert(err:find("não foi possivel abrir"), "erro deveria mencionar 'não foi possivel abrir'")
end)

-- Teste 5: Ler arquivo vazio
test("Ler arquivo vazio", function()
    local path = createTempFile("")
    local content = readFile(path)
    assert(content == "", "arquivo vazio deveria retornar string vazia")
    removeTempFile(path)
end)

-- Teste 6: Ler arquivo com caracteres especiais
test("Ler arquivo com caracteres especiais", function()
    local path = createTempFile("açúcar café naïve 日本語")
    local content = readFile(path)
    assert(content:find("açúcar"), "deveria preservar acentos")
    removeTempFile(path)
end)

-- Teste 7: Preserva whitespace
test("Preserva whitespace", function()
    local path = createTempFile("  espaços  \n\ttabs\t")
    local content = readFile(path)
    assert(content:find("  espaços  "), "deveria preservar espaços")
    assert(content:find("\t"), "deveria preservar tabs")
    removeTempFile(path)
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