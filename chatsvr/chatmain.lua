local skynet = require "skynet"

skynet.start(function()
    -- start chatsvr
    local chatsvr = skynet.uniqueservice("chatsvr")
    -- start chatgate
    local chat_port_from = assert(tonumber(skynet.getenv("chat_port_from")))
    local chat_port_to = assert(tonumber(skynet.getenv("chat_port_to")))
    local conf = {
        address = assert(tostring(skynet.getenv("chat_address"))),
        port = chat_port_from,
        maxclient = assert(tonumber(skynet.getenv("maxclient"))),
        nodelay = not not (skynet.getenv("nodelay") == "true")
    }
    repeat
        local chatgate = skynet.newservice("chatgate", chatsvr)
        skynet.call(chatgate, "lua", "open", conf)
        conf.port = conf.port + 1
    until(conf.port > chat_port_to)
    skynet.exit()
end)