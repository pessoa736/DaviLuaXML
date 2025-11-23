local parser = require("luaXML.parser")
local fcst = require("luaXML.functionCallToStringTransformer")

local function find_next_element(code, startPos)
  local pos = startPos or 1
  while true do
    local s, e, tagName = code:find("<([%w_]+)", pos)
    if not s then return nil end
    local gtPos = code:find(">", e + 1)
    local immediateClose = (gtPos == e + 1)
    if (tagName == "const" or tagName == "close") and immediateClose then
      pos = e + 1
    else
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

local function locate_full_tag(code, openStart)
  local s, e, tagName, attrs, selfClosed = code:find("<([%w_]+)%s*(.-)(/?)>", openStart)
  if not s then return nil, "Falha ao localizar abertura da tag" end
  if selfClosed == "/" then
    return s, e
  end
  local closeStart, closeEnd = code:find("</" .. tagName .. "%s*>", e + 1)
  if closeEnd then return s, closeEnd end
  local altStart, altEnd = code:find("<" .. tagName .. "%s*/>", e + 1)
  if altEnd then return s, altEnd end
  return nil, "Fechamento da tag não encontrado"
end

local function transform_code(code)
  local pos = 1
  while true do
    local openStart, tagName, element = find_next_element(code, pos)
    if not openStart then break end
    local s, tagEnd = locate_full_tag(code, openStart)
    if not s then break end
    local callStr = fcst(element)
    code = code:sub(1, s - 1) .. callStr .. code:sub(tagEnd + 1)
    pos = s + #callStr
  end
  return code
end

return {
  transform = transform_code
}
