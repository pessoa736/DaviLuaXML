local elements = require("luaXML.elements")
local insert = table.insert

local function trim(str)
  return (str:match("^%s*(.-)%s*$") or "")
end

local function leading_spaces(str)
  local prefix = str:match("^(%s*)")
  return prefix and #prefix or 0
end

local function parseAttributes(attrString)
    attrString = attrString and trim(attrString) or ""
    if attrString == "" then
        return nil
    end

    local attrs = {}
    local i, len = 1, #attrString

    local function skipWhitespace()
        while i <= len and attrString:sub(i, i):match("%s") do
            i = i + 1
        end
    end

    local function readName()
        local start = i
        while i <= len and attrString:sub(i, i):match("[-%w_:.]") do
            i = i + 1
        end
        if start == i then
            return nil
        end
        return attrString:sub(start, i - 1)
    end

    local function readValue()
        if i > len then
            return true
        end

        local ch = attrString:sub(i, i)

        if ch == '"' or ch == "'" then
            local quote = ch
            i = i + 1
            local start = i
            while i <= len and attrString:sub(i, i) ~= quote do
                i = i + 1
            end
            local value = attrString:sub(start, i - 1)
            if attrString:sub(i, i) == quote then
                i = i + 1
            end
            return value
        elseif ch == '{' then
            i = i + 1
            local start = i
            local depth = 1
            while i <= len do
                local current = attrString:sub(i, i)
                if current == '{' then
                    depth = depth + 1
                elseif current == '}' then
                    depth = depth - 1
                    if depth == 0 then
                        local value = attrString:sub(start, i - 1)
                        i = i + 1
                        value = trim(value)
                        -- tentar avaliar expressão dentro das chaves com segurança
                        local env = { math = math, tonumber = tonumber }
                        local fn, loadErr = load("return " .. value, "attr", "t", env)
                        if fn then
                            local ok, result = pcall(fn)
                            if ok then
                                return result
                            end
                        end
                        return value
                    end
                end
                i = i + 1
            end
            local value = trim(attrString:sub(start))
            local env = { math = math, tonumber = tonumber }
            local fn, loadErr = load("return " .. value, "attr", "t", env)
            if fn then
                local ok, result = pcall(fn)
                if ok then
                    return result
                end
            end
            return value
        else
            local start = i
            while i <= len and not attrString:sub(i, i):match("%s") do
                i = i + 1
            end
            return attrString:sub(start, i - 1)
        end
    end

    while i <= len do
        skipWhitespace()
        if i > len then
            break
        end

        local name = readName()
        if not name then
            break
        end

        skipWhitespace()
        local value
        if attrString:sub(i, i) == '=' then
            i = i + 1
            skipWhitespace()
            value = readValue()
        else
            value = true
        end

        attrs[name] = value
    end

    if next(attrs) == nil then
        return nil
    end

    return attrs
end

local function parseElement(code, globalStart)
    globalStart = globalStart or 1

    local leading = leading_spaces(code)
    code = trim(code)
    globalStart = globalStart + leading

    -- captura tag de abertura
    local startTagInit, startTagEnd, name, attrs, selfClosed = code:find("^<([%w_]+)%s*(.-)(/?)>")

    if not name then
        return nil, "Tag de abertura inválida"
    end

    -- ignorar tags reservadas do Lua (<const>, <close>) usadas em atributos / sintaxe
    if name == "const" or name == "close" then
        return nil, "Tag reservada Lua ignorada"
    end


    -- nó base
    local node = {
        name = name,
        attrs = parseAttributes(attrs),
        children = {}
    }

    local absoluteStart = globalStart + startTagInit - 1
    local absoluteEnd = globalStart + startTagEnd - 1

    -- se for <test .../>
    if selfClosed == "/" then
        return elements:createElement(node.name, node.attrs, {}), absoluteStart, absoluteEnd
    end

    -- agora precisamos achar o fechamento correspondente
    local i = startTagEnd + 1
    local depth = 0
    local contentStart = i

    while true do
        -- acha próxima abertura ou fechamento
        local nextOpen = code:find("<"..name.."%f[^%w_][^/]", i)
        local nextClose = code:find("</"..name.."%s*>", i)

        if not nextClose then
            return nil, "Tag de fechamento não encontrada para: " .. name
        end

        if nextOpen and nextOpen < nextClose then
            depth = depth + 1
            i = nextOpen + 1
        else
            if depth > 0 then
                depth = depth - 1
                i = nextClose + 1
            else
                -- achamos o fechamento correspondente
                local rawContent = code:sub(contentStart, nextClose - 1)
            if trim(rawContent) ~= "" then
                local pos = 1
                local len = #rawContent
                
                while pos <= len do
                    local openStart = rawContent:find("<([%w_]+)", pos)
                    if not openStart then break end
            
                    -- achar fechamento da tag encontrada
                    local segment = rawContent:sub(openStart)
                    local childOffset = globalStart + contentStart + openStart - 2
                    local child = select(1, parseElement(segment, childOffset))
                
                    if not child then
                        -- caso seja texto puro
                        break
                    end
                    
                    insert(node.children, child)
            
                    -- avançar posição até depois da tag parseada
                    local _, endTagEnd = segment:find("</"..child.tag.."%s*>")
                    if not endTagEnd then
                        -- autocontenida tipo <test/>
                        local selfClose = segment:find("/>")
                        if not selfClose then break end
                            pos = openStart + selfClose
                        else
                            pos = openStart + endTagEnd
                        end
                    end
                end

                return elements:createElement(node.name, node.attrs, node.children), absoluteStart, absoluteEnd
            end
        end
    end
end

local parser = setmetatable({}, {
  __call = function(_, code)
    return parseElement(code, 1)
  end
})

return parser
