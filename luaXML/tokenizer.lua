
local tokenizer = setmetatable({},
    {
        __call=function(s, ...)
            local args = {...} 
            return setmetatable(
                {
                    tag = args[1],
                    props = args[2],
                    children = args[3],
                },
                {
                    __tostring = function (s)
                        return "{tag = " .. s.tag .. ", props = " .. s.props .. ", children = " .. s.children .. "}"
                    end,
                    __concat = function (a, b)
                        return tostring(a) .. tostring(b)
                    end,
                }
            )
        end
    }
)

return tokenizer

