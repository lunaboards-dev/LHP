local lhp = require("lib.lhp")

local f = io.open(arg[1], "r")
local d = f:read("*a")
f:close()
--print(lhp.parse(d))
lhp.parse(d)