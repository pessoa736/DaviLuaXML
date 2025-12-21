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

local function getMapPath(cachePath)
    return cachePath:gsub("%.lua$", "") .. ".map.lua"
end

local function escapeLuaString(s)
    return string.format("%q", tostring(s))
end

local function serializeLua(value)
    local t = type(value)
    if t == "nil" then
        return "nil"
    elseif t == "string" then
        return escapeLuaString(value)
    elseif t == "number" or t == "boolean" then
        return tostring(value)
    elseif t == "table" then
        local isArray = true
        local max = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" then
                isArray = false
                break
            end
            if k > max then max = k end
        end

        local parts = {}
        if isArray then
            for i = 1, max do
                parts[#parts + 1] = serializeLua(value[i])
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end

        for k, v in pairs(value) do
            local key
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                key = k
            else
                key = "[" .. serializeLua(k) .. "]"
            end
            parts[#parts + 1] = key .. " = " .. serializeLua(v)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return escapeLuaString(tostring(value))
end

--------------------------------------------------------------------------------
-- API PÚBLICA
--------------------------------------------------------------------------------

--- Tenta obter código transformado do cache.
--- @param filepath string Caminho do arquivo .dslx original
--- @param content string Conteúdo atual do arquivo
--- @return string|nil Código transformado do cache, ou nil se não existir
--- @return table? map do cache
function M.get(filepath, content)
    if not M.enabled then
        return nil
    end
    
    local contentHash = hash(content)
    local cachePath = getCachePath(filepath, contentHash)
    local mapPath = getMapPath(cachePath)
    
    local f = io.open(cachePath, "r")
    if f then
        local cached = f:read("*a")
        f:close()
        logDebug("[cache] HIT:", filepath)

        local map
        local mf = io.open(mapPath, "r")
        if mf then
            local mcode = mf:read("*a")
            mf:close()
            local loader = load(mcode, "@" .. mapPath)
            if loader then
                local ok, res = pcall(loader)
                if ok and type(res) == "table" then
                    map = res
                end
            end
        end

        return cached, map
    end
    
    logDebug("[cache] MISS:", filepath)
    return nil
end

--- Salva código transformado no cache.
--- @param filepath string Caminho do arquivo .dslx original
--- @param content string Conteúdo original do arquivo
--- @param transformed string Código Lua transformado
--- @param map table|nil Sourcemap opcional
function M.set(filepath, content, transformed, map)
    if not M.enabled then
        return
    end
    
    ensureCacheDir()
    
    local contentHash = hash(content)
    local cachePath = getCachePath(filepath, contentHash)
    local mapPath = getMapPath(cachePath)
    
    local f = io.open(cachePath, "w")
    if f then
        f:write(transformed)
        f:close()
        logDebug("[cache] SET:", filepath, "->", cachePath)
    else
        logDebug("[cache] ERRO ao salvar:", cachePath)
    end

    if map and type(map) == "table" then
        local mf = io.open(mapPath, "w")
        if mf then
            mf:write("return ")
            mf:write(serializeLua(map))
            mf:write("\n")
            mf:close()
        end
    end
end

--- Limpa todo o cache.
function M.clear()
    os.execute("rm -rf " .. M.cacheDir .. "/*.lua 2>/dev/null")
    os.execute("rm -rf " .. M.cacheDir .. "/*.map.lua 2>/dev/null")
    logDebug("[cache] Cache limpo")
end

--- Retorna estatísticas do cache.
--- @return table { files = number, size = number, dir = M.cacheDir }
function M.stats()
    local handle, size, fileCount
    
    handle = io.popen("ls -la " .. M.cacheDir .. "/*.lua 2>/dev/null | wc -l")
    if handle then 
        fileCount = tonumber(handle:read("*a"):match("%d+")) or 0
        handle:close()
    end
        
    handle = io.popen("du -sh " .. M.cacheDir .. " 2>/dev/null")
    if handle then 
        size = handle:read("*a"):match("^(%S+)") or "0"
        handle:close()
    end 
    
    return {
        files = fileCount,
        size = size,
        dir = M.cacheDir
    }
end

return M
