--[[
    DaviLuaXML Init
    ============
    
    Módulo principal do DaviLuaXML. Registra um searcher customizado no Lua
    para permitir o uso de arquivos .dslx (Lua + XML) com require().
    
    FUNCIONALIDADE:
    ---------------
    Ao carregar este módulo, ele adiciona um searcher em package.searchers
    que intercepta chamadas require() e procura por arquivos .dslx correspondentes.
    
    Quando um arquivo .dslx é encontrado:
    1. Lê o conteúdo do arquivo
    2. Transforma as tags XML em chamadas de função Lua
    3. Compila e retorna o chunk resultante
    
    USO:
    ----
    -- No início do programa principal:
    require("DaviLuaXML")
    
    -- Agora você pode importar arquivos .dslx normalmente:
    local App = require("meu_componente")  -- carrega meu_componente.dslx
    
    EXEMPLO DE ARQUIVO .dslx:
    -----------------------
    -- arquivo: componente.dslx
    function Botao(props, children)
        return '<button class="' .. props.class .. '">' .. children[1] .. '</button>'
    end
    
    return <Botao class="primary">Clique aqui</Botao>
--]]

local readFile = require("DaviLuaXML.readFile")
local transform = require("DaviLuaXML.transform").transform
local errors = require("DaviLuaXML.errors")

if not _G.log then _G.log = require("loglua") end
local logDebug = _G.log.inSection("XMLRuntime")

--------------------------------------------------------------------------------
-- FUNÇÕES AUXILIARES
--------------------------------------------------------------------------------

--- Procura um arquivo pelo nome do módulo nos caminhos especificados.
--- Similar ao comportamento interno do Lua para encontrar módulos.
---
--- @param name string Nome do módulo (ex: "meu.modulo")
--- @param path string String de caminhos separados por ';' (ex: package.path)
--- @return string|nil Caminho completo do arquivo encontrado, ou nil
local function findfile(name, path)
	local pname = name:gsub("%.", "/")
	for template in string.gmatch(path, "[^;]+") do
		local filename = template:gsub("%?", pname)
		local f = io.open(filename, "r")
		if f then f:close(); return filename end
	end
end

--------------------------------------------------------------------------------
-- SEARCHER CUSTOMIZADO
--------------------------------------------------------------------------------

--- Searcher para arquivos .dslx (DaviLuaXML).
--- Procura arquivos .dslx, transforma o código XML em Lua puro e retorna o chunk.
---
--- @param modname string Nome do módulo sendo carregado via require()
--- @return function|string|nil Chunk compilado ou mensagem de erro
--- @return string|nil Caminho do arquivo (se encontrado)
local function lx_searcher(modname)
	logDebug("[searcher] Procurando módulo .dslx:", modname)
	
	-- Gerar path para .dslx baseado no package.path
	local lxpath = (package.path or ""):gsub("%.lua", ".dslx")
	local filename = findfile(modname, lxpath)
	
	if not filename then
		logDebug("[searcher] Módulo .dslx não encontrado:", modname)
		return "\n\tno .dslx file found for " .. modname
	end
	
	logDebug("[searcher] Arquivo encontrado:", filename)
	
	-- Ler, transformar e compilar
	local code = readFile(filename)
	logDebug("[searcher] Código lido, tamanho:", #code, "bytes")
	
	local transformed, transformErr = transform(code, filename)
	
	if transformErr or not transformed then
		logDebug("[searcher] ERRO na transformação:", transformErr)
		error(transformErr, 0)
	end
	
	local chunk, err = load(transformed, "@"..filename)
	
	if not chunk then
		logDebug("[searcher] ERRO na compilação:", err)
		error(errors.compilationError(tostring(err), filename), 0)
	end
	
	logDebug("[searcher] Módulo carregado com sucesso:", modname)
	return chunk, filename
end

--------------------------------------------------------------------------------
-- REGISTRO DO SEARCHER
--------------------------------------------------------------------------------

-- Registrar searcher apenas se ainda não estiver registrado
local already = false
for _, s in ipairs(package.searchers) do
	if s == lx_searcher then already = true; break end
end

if not already then
	-- Inserir na posição 2 (após o preload, antes dos outros)
	table.insert(package.searchers, 2, lx_searcher)
end

return true