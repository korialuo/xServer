local skynet = require "skynet"

skynet.start(function()
    local conf = {
        address = assert(tostring(skynet.getenv("chat_address"))),
        port = assert(tonumber(skynet.getenv("chat_port"))),
        maxclient = assert(tonumber(skynet.getenv("maxclient"))),
        nodelay = not not (skynet.getenv("nodelay") == "true")
    }
    local chatsvr = skynet.uniqueservice(true, "chatsvr")
    local chatgate = skynet.newservice("chatgate", chatsvr)

    skynet.call(chatgate, "lua", "open", conf)
    skynet.exit()
end)