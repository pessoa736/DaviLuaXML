--[[
    luaXML Function Call to String Transformer (fcst)
    ==================================================
    
    Converte um elemento parseado em uma string de chamada de função Lua.
    
    FUNCIONALIDADE:
    ---------------
    Transforma a estrutura de elemento { tag, props, children } em uma
    string que representa uma chamada de função Lua válida.
    
    EXEMPLO:
    --------
    Entrada (elemento):
        {
            tag = "div",
            props = { class = "container" },
            children = { "Olá", { tag = "span", props = {}, children = {} } }
        }
    
    Saída (string):
        'div({class = "container"},{[1] = "Olá",[2] = span({},{})})'
    
    USO:
    ----
    local fcst = require("luaXML.functionCallToStringTransformer")
    local callString = fcst(elemento)
--]]

--- Serializa um filho para string.
--- Se for um elemento (tabela com tag), converte recursivamente.
--- Se for string, coloca entre aspas.
--- Outros tipos são convertidos com tostring().
---
--- @param ch any Filho a ser serializado
--- @return string Representação do filho como string
local function serializeChild(ch)
    if type(ch) == "table" and ch.tag then
        return fcst(ch)
    elseif type(ch) == "string" then
        return string.format("'%s'", ch)
    else
        return tostring(ch)
    end
end

--- Converte um elemento em string de chamada de função.
--- Formato: tag(props, children)
---
--- @param element table Elemento com { tag, props, children }
--- @return string Chamada de função como string
local function fcst(element)
    -- Serializar children como tabela
    local childrens = "{"
    for idx, ch in ipairs(element.children) do
        childrens = childrens.."[".. idx .."] = " .. serializeChild(ch) .. ","
    end
    childrens = childrens .. "}"
    
    -- Montar chamada: tag(props, children)
    return element.tag .. "(" .. require("luaXML.tableToString")(element.props or {}, false) ..",".. childrens .. ")"
end

return fcst