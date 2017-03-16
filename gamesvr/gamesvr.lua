local skynet = require "skynet"
local session = require "session"
local sessionmgr = require "sessionmgr"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local randomlib = require "mt19937"
local zeropack = require "zeropack"

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
    sprotoloader.register(assert(skynet.getenv("root")).."proto/gamesvr.sproto", 1)
    proto = sprotoloader.load(1)
    session.proto(proto)
    -- random seed.
    randomlib.init(tostring(os.time()):reverse():sub(1, 6))
end)

skynet.dispatch("client", function(session, source, clisession, msg, ...)
    local cs = sessionmgr.find(clisession.fd)
    if not cs then return end
    local ok
    local compress, msgid, msgdata = string.unpack(">BHs2", msg)
    if compress then
        ok, msgdata = pcall(zeropack.unpack, msgdata)
        if not ok then
            skynet.error("gamesvr unpack msgdata error. fd: "..session.fd)
            return
        end
    end
    f(cs, msgdata, proto)
end)

skynet.dispatch("lua", function(session, source, command, ...)
    local f = assert(CMD[command])
    if session == 0 then
        f(source, ...)
    else
        skynet.retpack(f(source, ...))
    end
end)

skynet.start(function() end)