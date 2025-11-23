



local function serializeChild(ch)
    if type(ch) == "table" and ch.tag then
        return fcst(ch)
    elseif type(ch) == "string" then
        return string.format("'%s'", ch)
    else
        return tostring(ch)
    end
end

function fcst(element)
    local childrens = "{"
    for idx, ch in ipairs(element.children) do
        childrens = childrens.."[".. idx .."] = " .. serializeChild(ch) .. ","
    end
    childrens = childrens .. "}"
    return element.tag .. "(" .. require("luaXML.tableToString")(element.props or {}, false) ..",".. childrens .. ")"
end

return fcst