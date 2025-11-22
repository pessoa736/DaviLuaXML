
local parser = require("luaXML.parser")


parser:get_tag_full_body(
    [[
        <test>a</test>
    ]]
)

print(parser:get_tag_full_body(
    [[
        <test><test>a</test></test>
    ]]
))