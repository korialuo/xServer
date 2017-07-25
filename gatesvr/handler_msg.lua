local skynet = require "skynet"
local cluster = require "skynet.cluster"

local server_node

skynet.init(function()
    server_node = assert(skynet.getenv("server_node"))
end)

local MSG = {}

function MSG.redirect(clisession, msgdata)
    cluster.send(server_node, "mainsvr", "client", clisession, msgdata)
end

return MSG