local skynet = require "skynet"
local session = require "session"
local sessionmgr = require "sessionmgr"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    pack = skynet.pack,
    unpack = skynet.unpack
}

local proto
local MSG = require "handler_msg"
local CMD = require "handler_cmd"

skynet.init(function()
    -- load protocol
    sprotoloader.register(assert(skynet.getenv("root")).."proto/loginsvr.sproto", 1)
    proto = sprotoloader.load(1)
    session.proto(proto)
    -- register message
    MSG.register()
end)

skynet.dispatch("client", function(session, source, clisession, msg, ...)
    local cs = sessionmgr.find(clisession.fd)
    if not cs then return end
    local ok
    local compress, msgid, msgdata = string.unpack(">BHs2", msg)
    if compress then
        ok, msgdata = pcall(sproto.unpack, msgdata)
        if not ok then
            skynet.error("loginsvr unpack msgdata error. fd: "..clisession.fd)
            return
        end
    end
    MSG.dispatch(cs, msgid, msgdata)
end)

skynet.dispatch("lua", function(session, source, command, ...)
    local f = assert(CMD[command])
    skynet.retpack(f(source, ...))
end)

skynet.start(function() end)