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

local proto = {}
local MSG = require "handler_msg"
local CMD = require "handler_cmd"

skynet.init(function()
    sprotoloader.register(assert(skynet.getenv("root")).."proto/loginsvr.c2s", 1)
    sprotoloader.register(assert(skynet.getenv("root")).."proto/loginsvr.s2c", 2)
    proto.c2s = sprotoloader.load(1)
    proto.s2c = sprotoloader.load(2)
    session.proto(proto.s2c)
end)

skynet.start(function()
    skynet.dispatch("client", function(session, source, clisession, msg, ...)
        local ok, package = pcall(sproto.decode, proto.c2s, "package", msg)
        if ok then
            local f = MSG[package.msgname]
            if f then
                local cs = sessionmgr.find(clisession.fd)
                if not cs then
                    cs = sessionmgr.newsession(clisession)
                    sessionmgr.addsession(cs):bindgate(source)
                end
                f(cs, package.msgdata, proto)
            else
                skynet.error("loginsvr not registed handler for msgname: "..package.msgname)
            end
        else
            skynet.error("loginsvr parse sproto package error. fd: "..session.fd)
        end
    end)
    skynet.dispatch("lua", function(session, source, command, ...)
        local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
    end)
end)