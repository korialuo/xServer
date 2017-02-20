local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local socketdriver = require "socketdriver"
local netpack = require "netpack"
local crypt = require "crypt"

local mainsvr = assert(tonumber(...))
local sessions = {}
local handler = {}
local CMD = {}

function CMD.kick(fd)
    gateserver.closeclient(fd)
end

local function do_cleanup(fd)
    local session = sessions[fd]
    if session then
        session.proc = nil
        sessions[fd] = nil
    end
    skynet.send(mainsvr, "lua", "disconnect", session or fd)
end

local function do_dispatchmsg(session, msg, sz)
    local msgdata = netpack.tostring(msg, sz)
    local ok
    ok, msgdata = pcall(crypt.desdecode, session.secret, msgdata)
    if not ok then skynet.error("Des decode error, fd: "..session.fd) return end
    skynet.send(mainsvr, "client", session, msgdata)
end

local function do_verify(session, msg, sz)
    local ok, hmac = pcall(crypt.base64decode, netpack.tostring(msg, sz))
    if not ok then
        skynet.error("session("..session.fd..") do verify error. invalid base64str.")
        gateserver.closeclient(session.fd)
        return
    end
    local verify
    ok, verify = pcall(crypt.hmac_sha1, session.challenge, session.secret)
    if (not ok) or (hmac ~= verify) then
        skynet.error("session("..session.fd..") do verify error. verify failed.")
        gateserver.closeclient(session.fd)
        return
    end
    session.proc = nil
    skynet.send(mainsvr, "lua", "connect", session)
    session.proc = do_dispatchmsg
end

local function do_auth(session, msg, sz)
    if sz == 12 then
        local ok, cex = pcall(crypt.base64decode, netpack.tostring(msg, sz))
        if not ok then
            skynet.error("session("..session.fd..") do auth error. invalid base64str.")
            gateserver.closeclient(session.fd)
            return
        end
        local skey = crypt.randomkey()
        local sex = crypt.dhexchange(skey)
        session.secret = crypt.dhsecret(cex, skey)
        socketdriver.send(session.fd, netpack.pack(crypt.base64encode(sex)))
        session.proc = do_verify
    else
        skynet.error("session("..session.fd..") do auth error.")
        gateserver.closeclient(session.fd)
    end
end

local function do_handshake(session)
    session.challenge = crypt.randomkey()
    socketdriver.send(session.fd, netpack.pack(crypt.base64encode(session.challenge)))
    session.proc = do_auth
end

function handler.connect(fd, addr)
    local session = {
        fd = fd,
        addr = addr,
        challenge = nil,
        secret = nil,
        proc = nil
    }
    sessions[fd] = session
    gateserver.openclient(fd)
    do_handshake(session)
end

function handler.disconnect(fd)
    do_cleanup(fd)
end

function handler.error(fd, msg)
    skynet.error("session("..fd..") error: "..msg)
    gateserver.closeclient(fd)
end

function handler.message(fd, msg, sz)
    local session = sessions[fd]
    if session then
        session.proc(session, msg, sz)
    else
        skynet.error("Unknown session("..fd..").")
        gateserver.closeclient(fd)
    end
end

function handler.command(cmd, source, ...)
    local f = CMD[cmd]
    if f then
        return f(...)
    else
        skynet.error("Command '"..cmd.."' not registed.")
    end
end

function handler.warning(fd, size)
    skynet.error("session("..fd..") send buffer warning: high water marks !")
end

-- start a gatesvr service
gateserver.start(handler)