local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "skynet.manager"

skynet.start(function()
    -- start gamedb
    local gamedb = skynet.newservice("xmysql", "master", assert(tonumber(skynet.getenv("db_instance"))))
    skynet.name(".gamedb", gamedb)
    
    -- start gamesvr
    local gamesvr = skynet.uniqueservice("gamesvr")
    skynet.name(".mainsvr", gamesvr)
    cluster.open(assert(skynet.getenv("cluster_node")))
    
    -- start debug console
    local debug_console_port = assert(tonumber(skynet.getenv("debug_console_port")))
    skynet.newservice("debug_console", "0.0.0.0", debug_console_port)
    skynet.newservice("xconsole")
    skynet.exit()
end)