
local tokenizer = require("luaXML.tokenizer")
local gmatch = string.gmatch
local insert = table.insert


local function trim(str)
    return (str:match("^%s*(.-)%s*$") or "")
end


local function parse_props(attr)
    local props = {}
    for key, _, value in attr:gmatch("(%w+)%s*=%s*(['\"])%s*(.-)%s*%2") do
        props[key] = value
    end
    return props
end


local parser = setmetatable({},{
    __call = function (s, st)
    end
})


function parser.get_tag_full_body(s, str)
    if type(str) ~= "string" then
        error("expected string")
    end

    local normalized = trim(str)
    local tokens = {}

    for tag, attr, children in gmatch(normalized, "<(%w+)([^>]*)>%s*(.-)%s*</%1>") do
        local props = parse_props(attr or "")
        local nested = s.get_tag_full_body(s, children)
        local payload = nested

        if #nested == 0 then
            local text = trim(children)
            payload = text ~= "" and text or nil
        end

        insert(tokens, tokenizer(tag, props, payload))
    end

    return tokens
end

function parser.get_tag_compact(s, str)
    if type(str) ~= "string" then
        error("expected string")
    end
    
    local normalized = trim(str)
    local tokens = {}

    for tag, attr in gmatch(normalized, "<(%w+)([^>]*)%s*/>") do
        local props = parse_props(attr or "")
        insert(tokens, tokenizer(tag, props))
    end

    return tokens
end

function parser.Check(s, str)
    local ok, result = pcall(s.get_tag_full_body, s, str)
    if not ok then
        return false, result
    end
    return #result > 0, result
end



return parser
