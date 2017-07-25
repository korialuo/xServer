local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "skynet.manager"


skynet.start(function()
    -- start gatesvr
    local gatesvr = skynet.uniqueservice("gatesvr")
    skynet.name(".mainsvr", gatesvr)
    cluster.open(assert(skynet.getenv("cluster_node")))
    -- tcp
    local listen_port_tcp = assert(tonumber(skynet.getenv("listen_port_tcp")))
    local listen_address = assert(skynet.getenv("listen_address"))
    local conf = {
        address = listen_address,
        port = listen_port_tcp,
        maxclient = assert(tonumber(skynet.getenv("max_client"))),
        nodelay = skynet.getenv("nodelay") == "true"
    }
    local gate_tcp = skynet.newservice("xgate_tcp", gatesvr)
    skynet.name(".gatesvr", gate_tcp)
    skynet.call(gate_tcp, "lua", "open", conf)
    -- websocket
    --[[
    local listen_port_ws = assert(tonumber(skynet.getenv("listen_port_ws")))
    local gate_ws = skynet.newservice("xgate_ws", gatesvr)
    skynet.name(".gatesvr", gate_ws)
    skynet.call(gate_ws, "lua", "open", string.format("%s:%d", listen_address, listen_port_ws))
    --]]
    -- start debug console
    local debug_console_port = assert(tonumber(skynet.getenv("debug_console_port")))
    skynet.newservice("debug_console", "0.0.0.0", debug_console_port)
    skynet.newservice("xconsole")
    skynet.exit()
end)