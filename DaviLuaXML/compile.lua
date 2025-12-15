--[[
    DaviLuaXML Compile
    ==================
    
    Pré-compilador que transforma arquivos .dslx em arquivos .lua puros.
    Útil para deploy em produção sem dependência do transformador em runtime.
    
    FUNCIONALIDADE:
    ---------------
    - Transforma .dslx em .lua puro
    - Pode compilar arquivos individuais ou diretórios inteiros
    - Adiciona header informativo no arquivo gerado
    - Preserva estrutura de diretórios
    
    USO VIA MÓDULO:
    ---------------
    local compile = require("DaviLuaXML.compile")
    
    -- Compilar arquivo individual
    compile.file("app.dslx")                    -- gera app.lua
    compile.file("app.dslx", "dist/app.lua")   -- gera dist/app.lua
    
    -- Compilar diretório
    compile.dir("src/", "dist/")               -- compila todos .dslx de src/ para dist/
    
    USO VIA CLI:
    ------------
    lua -e 'require("DaviLuaXML.compile").cli()' app.dslx
    lua -e 'require("DaviLuaXML.compile").cli()' src/ dist/
    
    -- Ou via script dslxc (se instalado):
    dslxc app.dslx
    dslxc src/ dist/
--]]

local readFile = require("DaviLuaXML.readFile")
local transform = require("DaviLuaXML.transform").transform

if not _G.log then _G.log = require("loglua") end
local logDebug = _G.log.inSection("XMLCompile")

local M = {}

--------------------------------------------------------------------------------
-- CONFIGURAÇÃO
--------------------------------------------------------------------------------

--- Extensão dos arquivos de entrada
M.inputExtension = ".dslx"

--- Extensão dos arquivos de saída
M.outputExtension = ".lua"

--- Adicionar header informativo
M.addHeader = true

--- Versão do compilador
M.version = "1.0.0"

--------------------------------------------------------------------------------
-- FUNÇÕES AUXILIARES
--------------------------------------------------------------------------------

--- Gera o header do arquivo compilado
--- @param sourcePath string Caminho do arquivo original
--- @return string Header como comentário Lua
local function generateHeader(sourcePath)
    return string.format([[
-- ============================================================
-- Compiled by DaviLuaXML v%s
-- Source: %s
-- Date: %s
-- DO NOT EDIT - Changes will be lost on recompilation
-- ============================================================

]], M.version, sourcePath, os.date("%Y-%m-%d %H:%M:%S"))
end

--- Verifica se um caminho é um diretório
--- @param path string Caminho a verificar
--- @return boolean
local function isDirectory(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return false
    end
    -- Tentar como diretório
    local ok = os.execute("test -d " .. path .. " 2>/dev/null")
    return ok == true or ok == 0
end

--- Lista arquivos .dslx em um diretório (recursivo)
--- @param dir string Diretório a listar
--- @return table Lista de caminhos
local function listDslxFiles(dir)
    local files = {}
    local handle = io.popen('find "' .. dir .. '" -name "*' .. M.inputExtension .. '" -type f 2>/dev/null')
    if handle then
        for line in handle:lines() do
            table.insert(files, line)
        end
        handle:close()
    end
    return files
end

--- Garante que o diretório do arquivo existe
--- @param filepath string Caminho do arquivo
local function ensureDir(filepath)
    local dir = filepath:match("(.*/)")
    if dir then
        os.execute('mkdir -p "' .. dir .. '" 2>/dev/null')
    end
end

--------------------------------------------------------------------------------
-- API PÚBLICA
--------------------------------------------------------------------------------

--- Compila um único arquivo .dslx para .lua
--- @param inputPath string Caminho do arquivo .dslx
--- @param outputPath string|nil Caminho de saída (opcional, padrão: troca extensão)
--- @return boolean success
--- @return string|nil error
function M.file(inputPath, outputPath)
    logDebug("[compile] Compilando:", inputPath)
    
    -- Determinar caminho de saída
    if not outputPath then
        outputPath = inputPath:gsub(M.inputExtension .. "$", M.outputExtension)
    end
    
    -- Ler arquivo fonte
    local ok, content = pcall(readFile, inputPath)
    if not ok then
        return false, "Erro ao ler arquivo: " .. inputPath
    end
    
    -- Transformar
    local transformed, err = transform(content, inputPath)
    if err or not transformed then
        return false, "Erro na transformação: " .. (err or "unknown")
    end
    
    -- Adicionar header se configurado
    local output = transformed
    if M.addHeader then
        output = generateHeader(inputPath) .. transformed
    end
    
    -- Garantir que diretório existe
    ensureDir(outputPath)
    
    -- Escrever arquivo de saída
    local f = io.open(outputPath, "w")
    if not f then
        return false, "Erro ao criar arquivo: " .. outputPath
    end
    
    f:write(output)
    f:close()
    
    logDebug("[compile] Gerado:", outputPath)
    return true
end

--- Compila todos os arquivos .dslx de um diretório
--- @param inputDir string Diretório de entrada
--- @param outputDir string|nil Diretório de saída (opcional, padrão: mesmo diretório)
--- @return number successCount Número de arquivos compilados com sucesso
--- @return number failCount Número de arquivos com erro
--- @return table errors Lista de erros { {file, error}, ... }
function M.dir(inputDir, outputDir)
    logDebug("[compile] Compilando diretório:", inputDir)
    
    -- Normalizar paths
    inputDir = inputDir:gsub("/$", "")
    outputDir = outputDir and outputDir:gsub("/$", "") or inputDir
    
    local files = listDslxFiles(inputDir)
    local successCount = 0
    local failCount = 0
    local errors = {}
    
    for _, inputPath in ipairs(files) do
        -- Calcular caminho de saída mantendo estrutura de diretórios
        local relativePath = inputPath:sub(#inputDir + 2)
        local outputPath = outputDir .. "/" .. relativePath:gsub(M.inputExtension .. "$", M.outputExtension)
        
        local ok, err = M.file(inputPath, outputPath)
        if ok then
            successCount = successCount + 1
        else
            failCount = failCount + 1
            table.insert(errors, { file = inputPath, error = err })
        end
    end
    
    logDebug("[compile] Concluído:", successCount, "ok,", failCount, "erros")
    return successCount, failCount, errors
end

--- Interface de linha de comando
function M.cli()
    local args = arg or {}
    
    local function showHelp()
        print([[
DaviLuaXML Compiler v]] .. M.version .. [[


Usage:
  dslxc <file.dslx> [output.lua]     Compile a single file
  dslxc <inputDir/> [outputDir/]     Compile all .dslx files in directory

Examples:
  dslxc app.dslx                     -> app.lua
  dslxc app.dslx dist/app.lua        -> dist/app.lua
  dslxc src/ dist/                   -> compile src/*.dslx to dist/

Options:
  --no-header                        Don't add header comment to output
  --version                          Show version
  --help                             Show this help
]])
    end
    
    if #args == 0 then
        showHelp()
        return
    end
    
    -- Processar flags
    local input, output
    for i, a in ipairs(args) do
        if a == "--no-header" then
            M.addHeader = false
        elseif a == "--version" then
            print("DaviLuaXML Compiler v" .. M.version)
            return
        elseif a == "--help" then
            showHelp()
            return
        elseif not a:match("^%-") then
            if not input then
                input = a
            else
                output = a
            end
        end
    end
    
    if not input then
        print("Error: No input file or directory specified")
        os.exit(1)
    end
    
    -- Compilar
    if isDirectory(input) then
        local ok, fail, errors = M.dir(input, output)
        print(string.format("Compiled %d files, %d errors", ok, fail))
        for _, e in ipairs(errors) do
            print("  ERROR: " .. e.file .. ": " .. e.error)
        end
        os.exit(fail > 0 and 1 or 0)
    else
        local ok, err = M.file(input, output)
        if ok then
            print("Compiled: " .. input .. " -> " .. (output or input:gsub(M.inputExtension .. "$", M.outputExtension)))
        else
            print("Error: " .. err)
            os.exit(1)
        end
    end
end

return M
