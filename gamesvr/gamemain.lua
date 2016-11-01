local skynet = require "skynet"

skynet.start(function()
    -- start gamedb
    local db_instance = tonumber(skynet.getenv("db_instance"))
    local gamedb = skynet.newservice("mysqldb", "master", db_instance)
    -- start gamesvr
    local gamesvr = skynet.uniqueservice(true, "gamesvr", gamedb)
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