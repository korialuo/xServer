local skynet = require "skynet"
local utils = require "utils"

local WEB = { GET = {}, POST = {} }

WEB.GET["/"] = function(query)
    return "OK"
end

return WEB