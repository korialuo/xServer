local skynet = require "skynet"
local cluster = require "cluster"

skynet.start(function()
    -- start chatsvr
    local chat_servername = assert(skynet.getenv("chat_servername"))
    local chatsvr = skynet.uniqueservice("chatsvr")
    cluster.open(chat_servername)
    -- start chatgate
    -- tcp gate
    local chat_port_tcp = assert(tonumber(skynet.getenv("chat_port_tcp")))
    local chat_address = assert(skynet.getenv("chat_address"))
    local conf = {
        address = chat_address,
        port = chat_port_tcp,
        maxclient = assert(tonumber(skynet.getenv("maxclient"))),
        nodelay = skynet.getenv("nodelay") == "true"
    }
    local chatgate_tcp = skynet.newservice("xgate_tcp", chatsvr)
    skynet.call(chatgate_tcp, "lua", "open", conf)
    -- websocket gate
    local chat_port_ws = assert(tonumber(skynet.getenv("chat_port_ws")))
    local chatgate_ws = skynet.newservice("xgate_ws", chatsvr)
    skynet.call(chatgate_ws, "lua", "open", string.format("%s:%d", chat_address, chat_port_ws))
    -- start debug console
    local debug_console_port = assert(tonumber(skynet.getenv("debug_console_port")))
    skynet.newservice("debug_console", "0.0.0.0", debug_console_port)
    skynet.newservice("xconsole")
    skynet.exit()
end)