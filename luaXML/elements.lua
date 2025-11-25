--[[
    luaXML Elements
    ================

    Pequeno utilitário que provê uma factory para criar "elementos" usados
    pelo parser. Um elemento é uma tabela com os campos:

      - tag: string
      - props: tabela | nil
      - children: tabela

    O módulo exporta um objeto chamável (metatable) que aceita os argumentos
    `tag, props, children` e retorna uma tabela que implementa `__tostring`
    (para pretty-print) e `__concat` (para concatenar via tostring).

    Exemplo de uso:
      local elements = require("luaXML.elements")
      local el = elements("div", {class="x"}, {"conteudo"})

    Nota: `createElement` no campo da tabela é uma função simples que delega
    a chamada ao próprio metatable (compatibilidade com código externo).
]]

local elements = setmetatable({
        -- compatibilidade: createElement(tag, props, children)
        createElement = function (s, ...) return s(...) end
    },
    {
        -- Ao chamar o objeto: elements(tag, props, children)
        __call = function(s, ...)
            local args = {...}
            return setmetatable(
                {
                    tag = args[1],
                    props = args[2],
                    children = args[3],
                },
                {
                    -- Representação string legível via luaXML.tableToString
                    __tostring = require("luaXML.tableToString"),
                    -- Suporte a concatenação ('element' .. 'x') via tostring
                    __concat = function (a, b)
                        return tostring(a) .. tostring(b)
                    end
                }
            )
        end
    }
)

return elements

