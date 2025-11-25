--[[
    luaXML Props
    =============
    
    Módulo utilitário para conversão de propriedades (props) entre formatos.
    
    FUNCIONALIDADE:
    ---------------
    Converte propriedades entre tabela Lua e string de atributos XML/HTML.
    
    FUNÇÕES DISPONÍVEIS:
    --------------------
    
    1. tableToPropsString(props)
       Converte uma tabela de propriedades para string de atributos.
       
       Entrada:  { class = "titulo", id = "main", visible = true }
       Saída:    'class="titulo" id="main" visible="true"'
    
    2. stringToPropsTable(str)
       Converte uma string de atributos para tabela de propriedades.
       
       Entrada:  'class="titulo" count="5" active="true"'
       Saída:    { class = "titulo", count = 5, active = true }
       
       Nota: Valores "true"/"false" são convertidos para booleanos,
             valores numéricos são convertidos para numbers.
    
    USO:
    ----
    local props = require("luaXML.props")
    
    -- Tabela para string
    local str = props.tableToPropsString({ href = "link.com", target = "_blank" })
    -- Resultado: 'href="link.com" target="_blank"'
    
    -- String para tabela
    local tbl = props.stringToPropsTable('count="10" enabled="true"')
    -- Resultado: { count = 10, enabled = true }
]]--

local M = {}

local insert = table.insert
local concat = table.concat
local format = string.format

--------------------------------------------------------------------------------
-- CONVERSÃO: TABELA -> STRING
--------------------------------------------------------------------------------

--- Converte uma tabela de propriedades para uma string de atributos XML/HTML.
--- Cada propriedade é formatada como: chave="valor"
---
--- @param props table|nil Tabela de propriedades (pode ser nil)
--- @return string String de atributos separados por espaço, ou "" se props for nil/vazia
---
--- Exemplo:
---   tableToPropsString({ class = "btn", id = "submit" })
---   -- Retorna: 'class="btn" id="submit"'
function M.tableToPropsString(props)
    if not props then return "" end
    
    local parts = {}
    
    for k, v in pairs(props) do
        local t = type(v)
        
        if t == "string" then
            -- Strings: inserir diretamente
            insert(parts, format('%s="%s"', k, v))
        elseif t == "number" then
            -- Números: converter para string
            insert(parts, format('%s="%s"', k, tostring(v)))
        elseif t == "boolean" then
            -- Booleanos: "true" ou "false"
            insert(parts, format('%s="%s"', k, v and "true" or "false"))
        elseif t == "table" then
            -- Tabelas: usar tostring (comportamento básico)
            insert(parts, format('%s="%s"', k, tostring(v)))
        end
    end
    
    return concat(parts, " ")
end

--------------------------------------------------------------------------------
-- CONVERSÃO: STRING -> TABELA
--------------------------------------------------------------------------------

--- Converte uma string de atributos XML/HTML para uma tabela de propriedades.
--- Realiza conversão automática de tipos:
---   - "true"/"false" -> boolean
---   - Valores numéricos -> number
---   - Outros -> string
---
--- @param str string|nil String de atributos no formato 'chave="valor"'
--- @return table Tabela de propriedades, ou {} se str for nil/vazia
---
--- Exemplo:
---   stringToPropsTable('count="42" active="true" name="teste"')
---   -- Retorna: { count = 42, active = true, name = "teste" }
function M.stringToPropsTable(str)
    if not str or str == "" then return {} end
    
    local props = {}
    
    -- Pattern: captura pares chave="valor"
    for key, value in string.gmatch(str, '(%w+)%s*=%s*"([^"]*)"') do
        -- Conversão automática de tipos
        if value == "true" then
            props[key] = true
        elseif value == "false" then
            props[key] = false
        elseif tonumber(value) then
            props[key] = tonumber(value)
        else
            props[key] = value
        end
    end
    
    return props
end

return M
