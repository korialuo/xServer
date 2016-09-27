local skynet = require "skynet"

skynet.start(function()
    local conf = {
        address = assert(tostring(skynet.getenv("login_address"))),
        port = assert(tonumber(skynet.getenv("login_port"))),
        maxclient = assert(tonumber(skynet.getenv("maxclient"))),
        nodelay = not not (skynet.getenv("nodelay") == "true")
    }
    local login_instance = tonumber(skynet.getenv("login_instance"))
    local db_instance = tonumber(skynet.getenv("db_instance"))

    local logindb = skynet.newservice("logindb", "master", db_instance)
    local loginsvr = skynet.uniqueservice(true, "loginsvr", "master", logindb, login_instance)
    local logingate = skynet.newservice("logingate", loginsvr)

    skynet.call(logingate, "lua", "open", conf)
    skynet.exit()
end)