local skynet = require "skynet"

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    pack = skynet.pack,
    unpack = skynet.unpack
}

local MSG = require "handler_msg"
local CMD = require "handler_cmd"

skynet.dispatch("client", function(session, source, clisession, msg, ...)
    MSG.redirect(clisession, msg)
end)

skynet.dispatch("lua", function(session, source, command, ...)
    local f = assert(CMD[command])
    skynet.retpack(f(source, ...))
end)

skynet.start(function() end)