--[[
    DaviLuaXML Core
    ============
    
    Função principal para carregar e executar um arquivo .lx diretamente.
    
    FUNCIONALIDADE:
    ---------------
    1. Lê o conteúdo do arquivo .lx
    2. Transforma as tags XML em código Lua puro
    3. Compila e executa o código transformado
    4. Retorna o código transformado (ou erro)
    
    USO:
    ----
    local lx = require("DaviLuaXML.core")
    
    local resultado, erro = lx("meu_arquivo.lx")
    if erro then
        print("Erro:", erro)
    end
    
    DIFERENÇA PARA init.lua:
    ------------------------
    - init.lua: registra um searcher para usar require() com arquivos .lx
    - core.lua: executa diretamente um arquivo .lx pelo caminho
--]]

local readFile = require("DaviLuaXML.readFile")
local transform = require("DaviLuaXML.transform").transform
local errors = require("DaviLuaXML.errors")

if not _G.log then _G.log = require("loglua") end
local logDebug = _G.log.inSection("XMLRuntime")

--- Carrega, transforma e executa um arquivo .lx.
---
--- @param file string Caminho do arquivo .lx
--- @return string|nil Código transformado (se sucesso)
--- @return string|nil Mensagem de erro (se falha)
return function(file)
    logDebug("[core] Iniciando carregamento:", file)
    
    -- Tentar ler o arquivo
    local ok, code = pcall(readFile, file)
    if not ok then
        logDebug("[core] ERRO ao ler arquivo:", file)
        return nil, errors.format("não foi possível abrir o arquivo: " .. file)
    end
    logDebug("[core] Arquivo lido com sucesso, tamanho:", #code, "bytes")
    
    -- Transformar código
    local transformed, transformErr = transform(code, file)
    if transformErr or not transformed then
        logDebug("[core] ERRO na transformação:", transformErr)
        return nil, transformErr
    end
    logDebug("[core] Código transformado, tamanho:", #transformed, "bytes")

    -- Compilar
    local chunk, loadErr = load(transformed, "@"..file)
    if not chunk then
        logDebug("[core] ERRO na compilação:", loadErr)
        return nil, errors.compilationError(tostring(loadErr), file)
    end
    logDebug("[core] Código compilado com sucesso")
    
    -- Executar
    local execOk, runErr = pcall(chunk)
    if not execOk then
        logDebug("[core] ERRO na execução:", runErr)
        return nil, errors.runtimeError(tostring(runErr), file)
    end
    
    logDebug("[core] Execução concluída com sucesso:", file)
    return transformed
end