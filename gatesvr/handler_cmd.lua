local skynet = require "skynet"
local cluster = require "skynet.cluster"

local self_node, server_node

skynet.init(function()
    self_node = assert(skynet.getenv("cluster_node"))
    server_node = assert(skynet.getenv("server_node"))
end)

local CMD = {}

function CMD.connect(source, clisession)
    cluster.send(server_node, ".mainsvr", "connect", clisession, self_node)
end

function CMD.disconnect(source, clisession)
    cluster.send(server_node, ".mainsvr", "disconnect", clisession)
end


return CMD