local skynet = require "skynet"

skynet.start(function()
    local conf = {
        address = tostring(skynet.getenv("address")),
        port = tonumber(skynet.getenv("port")),
        maxclient = tonumber(skynet.getenv("maxclient")),
        nodelay = true
    }
    skynet.call(
        skynet.newservice("gatesvr", skynet.newservice("loginsvr", "master", 2)),
        "lua",
        "open",
        conf
    )
    skynet.exit()
end)