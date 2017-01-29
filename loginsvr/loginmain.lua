local skynet = require "skynet"
local cluster = require "cluster"
require "skynet.manager"

skynet.start(function()
    -- start logindb
    local logindb = skynet.newservice("xmysql", "master", assert(tonumber(skynet.getenv("db_instance"))))
    skynet.name(".logindb", logindb)
    -- start loginsvr
    local loginsvr = skynet.uniqueservice("loginsvr")
    skynet.name(".loginsvr", loginsvr)
    cluster.open("loginsvr")
    -- start logingate
    -- tcp gate
    local login_port_tcp = assert(tonumber(skynet.getenv("login_port_tcp")))
    local login_address = assert(skynet.getenv("login_address")) 
    local conf = {
        address = login_address,
        port = login_port_tcp,
        maxclient = assert(tonumber(skynet.getenv("maxclient"))),
        nodelay = skynet.getenv("nodelay") == "true"
    }
    local logingate_tcp = skynet.newservice("xgate_tcp", loginsvr)
    skynet.call(logingate_tcp, "lua", "open", conf)
    -- websocket gate
    local login_port_ws = assert(tonumber(skynet.getenv("login_port_ws")))
    local logingate_ws = skynet.newservice("xgate_ws", loginsvr)
    skynet.call(logingate_ws, "lua", "open", string.format("%s:%d", login_address, login_port_ws))
    -- start debug cosole
    local debug_console_port = assert(tonumber(skynet.getenv("debug_console_port")))
    skynet.newservice("debug_console", "0.0.0.0", debug_console_port)
    skynet.newservice("xconsole")
    skynet.exit()
end)