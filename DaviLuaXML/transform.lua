--[[
    DaviLuaXML Transform
    =================
    
    Módulo responsável por transformar código Lua contendo sintaxe XML
    em código Lua puro executável.
    
    FUNCIONALIDADE:
    ---------------
    Encontra todas as tags XML no código fonte e as substitui por chamadas
    de função Lua equivalentes.
    
    EXEMPLO DE TRANSFORMAÇÃO:
    -------------------------
    
    Entrada:
        local resultado = <soma a={2} b={3}/>
        print(<div class="container"> Olá </div>)
    
    Saída:
        local resultado = soma({a = 2, b = 3}, {})
        print(div({class = "container"}, {"Olá"}))
    
    FLUXO DE PROCESSAMENTO:
    -----------------------
    1. Busca a próxima tag XML no código (ignora tags Lua como <const>, <close>)
    2. Faz o parse da tag usando o módulo parser
    3. Localiza a posição completa da tag (abertura até fechamento)
    4. Converte o elemento parseado em chamada de função
    5. Substitui a tag original pela chamada de função
    6. Repete até não haver mais tags
    
    USO:
    ----
    local transform = require("DaviLuaXML.transform")
    local codigo_lua = transform.transform(codigo_lx)
    
    Exporta uma tabela com a funcao transform
--]]

local parser = require("DaviLuaXML.parser")

-- Preferir carregar a versão local do transformer (no workspace) quando disponível.
-- Primeiro tenta o novo `fcst_core.lua`, senão tenta o antigo `functionCallToStringTransformer.lua`,
-- por fim usa o `require` (caso esteja instalado globalmente).
local fcst
do
  local local_path = "DaviLuaXML/functionCallToStringTransformer.lua"
  local f = io.open(local_path, "r")
  if f then
    f:close()
    fcst = assert(dofile(local_path))
  else
    fcst = require("DaviLuaXML.functionCallToStringTransformer")
  end
end
local errors = require("DaviLuaXML.errors")

if not _G.log then _G.log = require("loglua") end
local logDebug = _G.log.inSection("XMLRuntime")

local function countLines(str)
  local _, n = tostring(str):gsub("\n", "\n")
  return n + 1
end

local function lineAt(code, pos)
  if pos <= 1 then
    return 1
  end
  local prefix = code:sub(1, pos - 1)
  local _, n = prefix:gsub("\n", "\n")
  return n + 1
end

--------------------------------------------------------------------------------
-- FUNÇÕES AUXILIARES
--------------------------------------------------------------------------------

--- Encontra o próximo elemento XML válido no código.
--- Ignora tags reservadas do Lua (<const>, <close>) quando usadas como atributos.
---
--- @param code string Código fonte a ser analisado
--- @param startPos number|nil Posição inicial da busca (padrão: 1)
--- @return number|nil Posição de início da tag encontrada
--- @return string|nil Nome da tag encontrada
--- @return table|nil Elemento parseado
local function find_next_element(code, startPos)
  local pos = startPos or 1
  
  while true do
    -- Buscar próxima abertura de tag
    local s, e, tagName = code:find("<([%w_]+)", pos)
    if not s then return nil end
    
    -- Verificar se é tag reservada Lua (<const> ou <close>)
    local gtPos = code:find(">", e + 1)
    local immediateClose = (gtPos == e + 1)
    
    if (tagName == "const" or tagName == "close") and immediateClose then
      -- Pular tags reservadas do Lua
      pos = e + 1
    else
      -- Tentar fazer parse do elemento
      local candidate = code:sub(s)
      local candElement = select(1, parser(candidate))
      
      if candElement then
        return s, tagName, candElement
      else
        pos = e + 1
      end
    end
  end
end

--- Localiza a extensão completa de uma tag (do '<' inicial até o '>' final).
--- Funciona para tags self-closing (<tag/>) e tags com fechamento (</tag>).
---
--- @param code string Código fonte
--- @param openStart number Posição do '<' de abertura
--- @return number|nil Posição inicial da tag
--- @return number|string|nil Posição final da tag ou mensagem de erro
local function locate_full_tag(code, openStart)
  local s, e, tagName, attrs, selfClosed = code:find("<([%w_]+)%s*(.-)(/?)>", openStart)
  
  if not s then 
    return nil, "Falha ao localizar abertura da tag" 
  end
  
  -- Tag self-closing: <tag ... />
  if selfClosed == "/" then
    return s, e
  end
  
  -- Buscar fechamento padrão: </tag>
  local closeStart, closeEnd = code:find("</" .. tagName .. "%s*>", e + 1)
  if closeEnd then 
    return s, closeEnd 
  end
  
  -- Buscar fechamento alternativo: <tag />
  local altStart, altEnd = code:find("<" .. tagName .. "%s*/>", e + 1)
  if altEnd then 
    return s, altEnd 
  end
  
  return nil, "Fechamento da tag não encontrado"
end

--------------------------------------------------------------------------------
-- FUNÇÃO PRINCIPAL
--------------------------------------------------------------------------------

--- Transforma código com sintaxe XML em código Lua puro.
--- Substitui todas as tags XML por chamadas de função equivalentes.
---
--- @param code string Código fonte contendo tags XML
--- @param filename string|nil Nome do arquivo (para mensagens de erro)
--- @return string|nil Código Lua puro com as tags substituídas por chamadas de função
--- @return string|nil Mensagem de erro (se houver)
---
--- Exemplo:
---   transform_code('<btn onClick={handler}>Clique</btn>')
---   -- Retorna: 'btn({onClick = handler}, {"Clique"})'
local function transform_code(code, filename, options)
  logDebug("[transform] Iniciando transformação:", filename or "<string>")
  local pos = 1
  local originalCode = code
  local tagCount = 0

  options = options or {}
  local injectRuntime = (options.injectRuntime ~= false)

  local map = {
    filename = filename,
    headerLines = 0,
    checkpoints = {},
  }
  local cumulativeDelta = 0
  
  while true do
    -- Encontrar próximo elemento
    local openStart, tagName, element = find_next_element(code, pos)
    if not openStart or not element then break end
    
    tagCount = tagCount + 1
    logDebug("[transform] Tag encontrada #" .. tagCount .. ":", "<" .. tagName .. ">")
    
    -- Localizar extensão completa da tag
    local s, tagEnd = locate_full_tag(code, openStart)
    if not s then 
      logDebug("[transform] ERRO: tag não fechada:", tagName)
      -- Calcular posição no código original para erro
      ---@diagnostic disable-next-line: param-type-mismatch
      return nil, errors.unclosedTag(tagName, originalCode, openStart, filename)
    end
    
    -- Converter elemento em chamada de função
    local callStr = fcst(element)
    logDebug("[transform] Convertido para:", callStr:sub(1, 60) .. (#callStr > 60 and "..." or ""))

    -- Atualizar sourcemap (delta de linhas)
    local originalTagText = code:sub(s, tagEnd)
    local origLines = countLines(originalTagText)
    local newLines = countLines(callStr)
    cumulativeDelta = cumulativeDelta + (origLines - newLines)
    table.insert(map.checkpoints, {
      line = lineAt(code, s),
      delta = cumulativeDelta,
    })
    
    -- Substituir tag pelo código Lua
    code = code:sub(1, s - 1) .. callStr .. code:sub(tagEnd + 1)
    
    -- Avançar posição após a substituição
    pos = s + #callStr
  end
  
  if injectRuntime and tagCount > 0 then
    code = 'local __daviluaxml_invoke = require("DaviLuaXML.runtime").invoke\n' .. code
    map.headerLines = 1
  end

  logDebug("[transform] Transformação concluída:", tagCount, "tags processadas")
  return code, nil, map
end

--------------------------------------------------------------------------------
-- EXPORTAÇÃO DO MÓDULO
--------------------------------------------------------------------------------

return {
  transform = transform_code
}
