--[[
    luaXML Core
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
    local lx = require("luaXML.core")
    
    local resultado, erro = lx("meu_arquivo.lx")
    if erro then
        print("Erro:", erro)
    end
    
    DIFERENÇA PARA init.lua:
    ------------------------
    - init.lua: registra um searcher para usar require() com arquivos .lx
    - core.lua: executa diretamente um arquivo .lx pelo caminho
--]]

local readFile = require("luaXML.readFile")
local transform = require("luaXML.transform").transform

--- Carrega, transforma e executa um arquivo .lx.
---
--- @param file string Caminho do arquivo .lx
--- @return string|nil Código transformado (se sucesso)
--- @return string|nil Mensagem de erro (se falha)
return function(file)
    local code = readFile(file)
    local transformed = transform(code)

    local chunk, loadErr = load(transformed, "@"..file)
    if not chunk then
        return nil, "Erro ao compilar código transformado: " .. tostring(loadErr)
    end
    
    local ok, runErr = pcall(chunk)
    if not ok then
        return nil, "Erro ao executar código transformado: " .. tostring(runErr)
    end

    return transformed
end