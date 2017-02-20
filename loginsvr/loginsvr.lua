local skynet = require "skynet"
local session = require "session"
local sessionmgr = require "sessionmgr"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local lzc = require "lzc"

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    pack = skynet.pack,
    unpack = skynet.unpack
}

local proto = {}
local MSG = require "handler_msg"
local CMD = require "handler_cmd"

skynet.init(function()
    proto.wrap = sproto.parse [[
        .MessageWrap {
            msgid 0 : integer
            compress 1 : boolean
            msgdata 2 : string
        }
    ]]
    sprotoloader.register(assert(skynet.getenv("root")).."proto/loginsvr.sproto", 1)
    proto.proto = sprotoloader.load(1)
    session.proto(proto)
end)

skynet.dispatch("client", function(session, source, clisession, msg, ...)
    local cs = sessionmgr.find(clisession.fd)
    if not cs then return end
    local ok, wrap = pcall(sproto.decode, proto.wrap, "MessageWrap", msg)
    if ok then
        local f = MSG[wrap.msgid]
        if f then
            if wrap.compress then wrap.msgdata = lzc.decompress(wrap.msgdata) end
            f(cs, wrap.msgdata, proto)
        else
            skynet.error("loginsvr not registed handler for msgid: "..wrap.msgid)
        end
    else
        skynet.error("loginsvr parse sproto package error. fd: "..session.fd)
    end
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