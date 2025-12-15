--[[
    DaviLuaXML Cache
    ================
    
    Sistema de cache para evitar re-transformar arquivos .dslx que não mudaram.
    
    FUNCIONALIDADE:
    ---------------
    - Calcula hash do conteúdo do arquivo
    - Armazena código transformado em ~/.cache/daviluaxml/
    - Retorna cache se arquivo não mudou
    
    USO:
    ----
    local cache = require("DaviLuaXML.cache")
    
    -- Tentar obter do cache
    local cached = cache.get(filepath, content)
    if cached then
        return cached
    end
    
    -- Transformar e salvar no cache
    local transformed = transform(content)
    cache.set(filepath, content, transformed)
--]]

if not _G.log then _G.log = require("loglua") end
local logDebug = _G.log.inSection("XMLCache")

local M = {}

--------------------------------------------------------------------------------
-- CONFIGURAÇÃO
--------------------------------------------------------------------------------

--- Diretório de cache
M.cacheDir = os.getenv("HOME") .. "/.cache/daviluaxml"

--- Habilitar/desabilitar cache (útil para debug)
M.enabled = true

--------------------------------------------------------------------------------
-- FUNÇÕES AUXILIARES
--------------------------------------------------------------------------------

--- Calcula um hash simples do conteúdo (djb2 algorithm)
--- @param str string Conteúdo para calcular hash
--- @return string Hash em hexadecimal
local function hash(str)
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + str:byte(i)) % 0xFFFFFFFF
    end
    return string.format("%08x", h)
end

--- Garante que o diretório de cache existe
local function ensureCacheDir()
    os.execute("mkdir -p " .. M.cacheDir .. " 2>/dev/null")
end

--- Gera o caminho do arquivo de cache baseado no filepath e hash do conteúdo
--- @param filepath string Caminho do arquivo original
--- @param contentHash string Hash do conteúdo
--- @return string Caminho do arquivo de cache
local function getCachePath(filepath, contentHash)
    -- Usar hash do filepath + hash do conteúdo para nome único
    local pathHash = hash(filepath)
    return string.format("%s/%s_%s.lua", M.cacheDir, pathHash, contentHash)
end

--------------------------------------------------------------------------------
-- API PÚBLICA
--------------------------------------------------------------------------------

--- Tenta obter código transformado do cache.
--- @param filepath string Caminho do arquivo .dslx original
--- @param content string Conteúdo atual do arquivo
--- @return string|nil Código transformado do cache, ou nil se não existir
function M.get(filepath, content)
    if not M.enabled then
        return nil
    end
    
    local contentHash = hash(content)
    local cachePath = getCachePath(filepath, contentHash)
    
    local f = io.open(cachePath, "r")
    if f then
        local cached = f:read("*a")
        f:close()
        logDebug("[cache] HIT:", filepath)
        return cached
    end
    
    logDebug("[cache] MISS:", filepath)
    return nil
end

--- Salva código transformado no cache.
--- @param filepath string Caminho do arquivo .dslx original
--- @param content string Conteúdo original do arquivo
--- @param transformed string Código Lua transformado
function M.set(filepath, content, transformed)
    if not M.enabled then
        return
    end
    
    ensureCacheDir()
    
    local contentHash = hash(content)
    local cachePath = getCachePath(filepath, contentHash)
    
    local f = io.open(cachePath, "w")
    if f then
        -- Adicionar metadata como comentário
        f:write(string.format(
            "-- DaviLuaXML Cache\n-- Source: %s\n-- Hash: %s\n-- Generated: %s\n\n",
            filepath,
            contentHash,
            os.date("%Y-%m-%d %H:%M:%S")
        ))
        f:write(transformed)
        f:close()
        logDebug("[cache] SET:", filepath, "->", cachePath)
    else
        logDebug("[cache] ERRO ao salvar:", cachePath)
    end
end

--- Limpa todo o cache.
function M.clear()
    os.execute("rm -rf " .. M.cacheDir .. "/*.lua 2>/dev/null")
    logDebug("[cache] Cache limpo")
end

--- Retorna estatísticas do cache.
--- @return table { files = number, size = number }
function M.stats()
    local handle = io.popen("ls -la " .. M.cacheDir .. "/*.lua 2>/dev/null | wc -l")
    local fileCount = tonumber(handle:read("*a"):match("%d+")) or 0
    handle:close()
    
    handle = io.popen("du -sh " .. M.cacheDir .. " 2>/dev/null")
    local size = handle:read("*a"):match("^(%S+)") or "0"
    handle:close()
    
    return {
        files = fileCount,
        size = size,
        dir = M.cacheDir
    }
end

return M
