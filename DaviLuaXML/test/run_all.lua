#!/usr/bin/env lua
--[[
    Runner de testes para o projeto DaviLuaXML
    
    Executa todos os arquivos de teste e reporta os resultados.
    
    Uso:
        lua DaviLuaXML/test/run_all.lua
        
    Ou com cd para o diretório do projeto:
        cd /caminho/para/DaviLuaXML
        lua DaviLuaXML/test/run_all.lua
]]

-- Configurar package.path para encontrar loglua em lua_modules
local scriptPath = arg[0]
local projectRoot = scriptPath:match("(.+)/DaviLuaXML/test/run_all%.lua$") or "."
package.path = projectRoot .. "/lua_modules/share/lua/5.4/?.lua;"
            .. projectRoot .. "/lua_modules/share/lua/5.4/?/init.lua;"
            .. projectRoot .. "/?.lua;"
            .. projectRoot .. "/?/init.lua;"
            .. package.path

_G.log = _G.log or require("loglua")
log.live()  -- Ativa modo live para mostrar logs em tempo real
local logRunner = log.inSection("runner")

logRunner("╔══════════════════════════════════════════════════╗")
logRunner("║          DaviLuaXML - Suite de Testes            ║")
logRunner("╚══════════════════════════════════════════════════╝\n")

-- Lista de arquivos de teste
local testFiles = {
    "parser",
    "props",
    "elements",
    "errors",
    "tableToString",
    "transform",
    "fcst",
    "proptypes",
    "sourcemap",
    "treeshake",
    "readFile",
    "cache",
    "compile",
    "core",
    "init",
    "help",
    "callFunction",
    "import_lx"
}

local results = {
    passed = {},
    failed = {},
    skipped = {}
}

-- Função para executar um teste
local function runTest(name)
    logRunner(string.format("\n▶ Executando: %s.lua", name))
    logRunner(string.rep("-", 50))
    
    local testPath = projectRoot .. "/DaviLuaXML/test/" .. name .. ".lua"
    
    -- Verificar se arquivo existe
    local f = io.open(testPath, "r")
    if not f then
        logRunner("   ⚠ Arquivo não encontrado: " .. testPath)
        table.insert(results.skipped, name)
        return
    end
    f:close()
    
    -- Executar teste em um processo separado para isolamento
    -- Passa o package.path para os subprocessos encontrarem loglua
    local luaPath = projectRoot .. "/lua_modules/share/lua/5.4/?.lua;"
                 .. projectRoot .. "/lua_modules/share/lua/5.4/?/init.lua;"
                 .. projectRoot .. "/?.lua;"
                 .. projectRoot .. "/?/init.lua"
    
    local cmd = string.format(
        'cd "%s" && LUA_PATH="%s;;" lua "%s" 2>&1',
        projectRoot,
        luaPath,
        testPath
    )
    
    local handle = io.popen(cmd)
    if not handle then
        logRunner("   ✗ Falha ao executar")
        table.insert(results.failed, {name = name, error = "Falha ao executar comando"})
        return
    end
    
    local output = handle:read("*a")
    local success, exitType, exitCode = handle:close()
    
    -- Mostrar saída
    logRunner(output)
    
    -- Verificar resultado
    if success or (exitType == "exit" and exitCode == 0) then
        table.insert(results.passed, name)
    else
        table.insert(results.failed, {
            name = name, 
            error = string.format("Código de saída: %s", tostring(exitCode or "desconhecido"))
        })
    end
end

-- Executar todos os testes
for _, testName in ipairs(testFiles) do
    runTest(testName)
end

-- Relatório final
logRunner("\n")
logRunner("╔══════════════════════════════════════════════════╗")
logRunner("║                   RESULTADO                      ║")
logRunner("╚══════════════════════════════════════════════════╝\n")

logRunner(string.format("✓ Passaram:  %d testes", #results.passed))
for _, name in ipairs(results.passed) do
    logRunner(string.format("    • %s", name))
end

if #results.skipped > 0 then
    logRunner(string.format("\n⚠ Pulados:   %d testes", #results.skipped))
    for _, name in ipairs(results.skipped) do
        logRunner(string.format("    • %s", name))
    end
end

if #results.failed > 0 then
    logRunner(string.format("\n✗ Falharam:  %d testes", #results.failed))
    for _, result in ipairs(results.failed) do
        logRunner(string.format("    • %s: %s", result.name, result.error))
    end
end

logRunner("\n" .. string.rep("═", 52))
logRunner(string.format("Total: %d passaram, %d pulados, %d falharam",
    #results.passed, #results.skipped, #results.failed))
logRunner(string.rep("═", 52))

log.show({"runner", "XMLRuntime"})

-- Código de saída
if #results.failed > 0 then
    os.exit(1)
else
    os.exit(0)
end


