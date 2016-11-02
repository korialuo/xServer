local skynet = require "skynet"
local cluster = require "cluster"

skynet.start(function()
    -- start gamedb
    local db_instance = tonumber(skynet.getenv("db_instance"))
    local gamedb = skynet.newservice("mysqldb", "master", db_instance)
    -- start gamesvr
    local game_servername = assert(skynet.getenv("game_servername"))
    local gamesvr = skynet.uniqueservice("gamesvr", gamedb)
    cluster.open(game_servername)
    -- start gamegate
    local game_port_from = assert(tonumber(skynet.getenv("game_port_from")))
    local game_port_to = assert(tonumber(skynet.getenv("game_port_to")))
    local conf = {
        address = assert(tostring(skynet.getenv("game_address"))),
        port = game_port_from,
        maxclient = assert(tonumber(skynet.getenv("maxclient"))),
        nodelay = not not (skynet.getenv("nodelay") == "true")
    }
    repeat
        local gamegate = skynet.newservice("gamegate", gamesvr)
        skynet.call(gamegate, "lua", "open", conf)
        conf.port = conf.port + 1
    until(conf.port > game_port_to)
    skynet.exit()
end)