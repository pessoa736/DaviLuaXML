--[[
    luaXML Init
    ============
    
    Módulo principal do luaXML. Registra um searcher customizado no Lua
    para permitir o uso de arquivos .lx (Lua + XML) com require().
    
    FUNCIONALIDADE:
    ---------------
    Ao carregar este módulo, ele adiciona um searcher em package.searchers
    que intercepta chamadas require() e procura por arquivos .lx correspondentes.
    
    Quando um arquivo .lx é encontrado:
    1. Lê o conteúdo do arquivo
    2. Transforma as tags XML em chamadas de função Lua
    3. Compila e retorna o chunk resultante
    
    USO:
    ----
    -- No início do programa principal:
    require("luaXML")
    
    -- Agora você pode importar arquivos .lx normalmente:
    local App = require("meu_componente")  -- carrega meu_componente.lx
    
    EXEMPLO DE ARQUIVO .lx:
    -----------------------
    -- arquivo: componente.lx
    function Botao(props, children)
        return '<button class="' .. props.class .. '">' .. children[1] .. '</button>'
    end
    
    return <Botao class="primary">Clique aqui</Botao>
--]]

local readFile = require("luaXML.readFile")
local transform = require("luaXML.transform").transform

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

--- Searcher para arquivos .lx (luaXML).
--- Procura arquivos .lx, transforma o código XML em Lua puro e retorna o chunk.
---
--- @param modname string Nome do módulo sendo carregado via require()
--- @return function|string|nil Chunk compilado ou mensagem de erro
--- @return string|nil Caminho do arquivo (se encontrado)
local function lx_searcher(modname)
	-- Gerar path para .lx baseado no package.path
	local lxpath = (package.path or ""):gsub("%.lua", ".lx")
	local filename = findfile(modname, lxpath)
	
	if not filename then
		return "\n\tno .lx file found for " .. modname
	end
	
	-- Ler, transformar e compilar
	local code = readFile(filename)
	local transformed = transform(code)
	local chunk, err = load(transformed, "@"..filename)
	
	if not chunk then return err end
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