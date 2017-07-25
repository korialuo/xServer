local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "skynet.manager"

skynet.start(function()
    -- start logindb
    local logindb = skynet.newservice("xmysql", "master", assert(tonumber(skynet.getenv("db_instance"))))
    skynet.name(".logindb", logindb)
    
    -- start loginsvr
    local loginsvr = skynet.uniqueservice("loginsvr")
    skynet.name(".mainsvr", loginsvr)
    cluster.open(assert(skynet.getenv("cluster_node")))
    
    -- start debug cosole
    local debug_console_port = assert(tonumber(skynet.getenv("debug_console_port")))
    skynet.newservice("debug_console", "0.0.0.0", debug_console_port)
    skynet.newservice("xconsole")
    skynet.exit()
end)