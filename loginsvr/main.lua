local skynet = require "skynet"

skynet.start(function()
    local conf = {
        address = assert(tostring(skynet.getenv("address"))),
        port = assert(tonumber(skynet.getenv("port"))),
        maxclient = assert(tonumber(skynet.getenv("maxclient"))),
        nodelay = not not (skynet.getenv("nodelay") == "true")
    }
    local instance = tonumber(skynet.getenv("instance"))
    skynet.call(
        skynet.newservice("gatesvr", skynet.newservice("loginsvr", "master", instance)),
        "lua",
        "open",
        conf
    )
    skynet.exit()
end)