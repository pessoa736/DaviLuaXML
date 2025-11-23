local readFile = require("luaXML.readFile")
local transform = require("luaXML.transform").transform

local function findfile(name, path)
	local pname = name:gsub("%.", "/")
	for template in string.gmatch(path, "[^;]+") do
		local filename = template:gsub("%?", pname)
		local f = io.open(filename, "r")
		if f then f:close(); return filename end
	end
end

local function lx_searcher(modname)
	local lxpath = (package.path or ""):gsub("%.lua", ".lx")
	local filename = findfile(modname, lxpath)
	if not filename then
		return "\n\tno .lx file found for " .. modname
	end
	local code = readFile(filename)
	local transformed = transform(code)
	local chunk, err = load(transformed, "@"..filename)
	if not chunk then return err end
	return chunk, filename
end

-- register searcher if not already
local already = false
for _, s in ipairs(package.searchers) do
	if s == lx_searcher then already = true; break end
end
if not already then
	table.insert(package.searchers, 2, lx_searcher)
end

return true