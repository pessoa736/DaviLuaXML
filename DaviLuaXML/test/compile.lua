--[[
    Testes do módulo compile.lua
    
    O compilador transforma arquivos .dslx em .lua puros.
]]

_G.log = _G.log or require("loglua")
local logTest = log.inSection("compile")

logTest("=== TESTE: compile.lua ===")

local compile = require("DaviLuaXML.compile")

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

-- Criar arquivo temporário para testes
local testDir = "/tmp/dslx_compile_test_" .. os.time()
os.execute("mkdir -p " .. testDir)

local testInputFile = testDir .. "/test.dslx"
local testOutputFile = testDir .. "/test.lua"

-- Escrever arquivo de teste
local testInput = [[
local function Button(props, children)
    return {tag = "button", props = props, children = children}
end

return <Button class="primary">Click me</Button>
]]

local f = io.open(testInputFile, "w")
f:write(testInput)
f:close()

-- Teste 1: Compilar arquivo individual
test("Compilar arquivo individual", function()
    local ok, err = compile.file(testInputFile, testOutputFile)
    assert(ok, "compilação deveria ter sucesso: " .. tostring(err))
    
    -- Verificar se arquivo foi criado
    local f = io.open(testOutputFile, "r")
    assert(f, "arquivo de saída deveria existir")
    
    local content = f:read("*a")
    f:close()
    
    assert(content:find("Button%("), "deveria conter chamada Button()")
    assert(content:find("Compiled by DaviLuaXML"), "deveria conter header")
end)

-- Teste 2: Compilar com caminho de saída automático
test("Compilar com caminho de saída automático", function()
    local inputPath = testDir .. "/auto.dslx"
    local expectedOutput = testDir .. "/auto.lua"
    
    -- Criar arquivo
    local f = io.open(inputPath, "w")
    f:write("return <div/>")
    f:close()
    
    local ok = compile.file(inputPath)
    assert(ok, "compilação deveria ter sucesso")
    
    -- Verificar arquivo criado
    f = io.open(expectedOutput, "r")
    assert(f, "arquivo .lua deveria ser criado automaticamente")
    f:close()
end)

-- Teste 3: Erro em arquivo inexistente
test("Erro em arquivo inexistente", function()
    local ok, err = compile.file("/tmp/nao_existe_xyz_123.dslx")
    assert(not ok, "deveria falhar para arquivo inexistente")
    assert(err:find("Erro"), "deveria retornar mensagem de erro")
end)

-- Teste 4: Compilar sem header
test("Compilar sem header", function()
    local inputPath = testDir .. "/noheader.dslx"
    local outputPath = testDir .. "/noheader.lua"
    
    local f = io.open(inputPath, "w")
    f:write("return <span/>")
    f:close()
    
    -- Desabilitar header
    local originalHeader = compile.addHeader
    compile.addHeader = false
    
    compile.file(inputPath, outputPath)
    
    compile.addHeader = originalHeader
    
    -- Verificar
    f = io.open(outputPath, "r")
    local content = f:read("*a")
    f:close()
    
    assert(not content:find("Compiled by"), "não deveria conter header")
end)

-- Teste 5: Compilar diretório
test("Compilar diretório", function()
    local srcDir = testDir .. "/src"
    local distDir = testDir .. "/dist"
    
    os.execute("mkdir -p " .. srcDir)
    
    -- Criar alguns arquivos
    local f = io.open(srcDir .. "/a.dslx", "w")
    f:write("return <div/>")
    f:close()
    
    f = io.open(srcDir .. "/b.dslx", "w")
    f:write("return <span/>")
    f:close()
    
    local ok, fail, errors = compile.dir(srcDir, distDir)
    
    assert(ok == 2, "deveria compilar 2 arquivos com sucesso")
    assert(fail == 0, "não deveria ter erros")
    
    -- Verificar arquivos criados
    f = io.open(distDir .. "/a.lua", "r")
    assert(f, "a.lua deveria existir")
    f:close()
    
    f = io.open(distDir .. "/b.lua", "r")
    assert(f, "b.lua deveria existir")
    f:close()
end)

-- Teste 6: Configurações do módulo
test("Configurações do módulo", function()
    assert(compile.inputExtension == ".dslx", "extensão de entrada deveria ser .dslx")
    assert(compile.outputExtension == ".lua", "extensão de saída deveria ser .lua")
    assert(type(compile.version) == "string", "versão deveria ser string")
end)

-- Limpar arquivos de teste
os.execute("rm -rf " .. testDir)

-- Resumo
logTest("")
logTest(string.format("=== RESULTADO: %d passou, %d falhou ===", passed, failed))

return {
    passed = passed,
    failed = failed
}
