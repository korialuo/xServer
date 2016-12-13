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
    if session then sessions[fd] = nil end
end

local function do_dispatchmsg(session, msg, sz)
    local msgdata = netpack.tostring(msg, sz)
    local ok = false
    ok, msgdata = pcall(crypt.desdecode, session.secret, msgdata)
    if not ok then skynet.error("Des decode error, fd: "..session.fd) return end
    ok, msgdata = pcall(crypt.base64decode(msgdata))
    if not ok then skynet.error("Base64 decode error: fd: ".. session.fd) return end
    skynet.send(mainsvr, "client", session, msgdata)
end

local function do_verify(session, msg, sz)
    local hmac = crypt.base64decode(netpack.tostring(msg, sz))
    local verify = crypt.hmac64(session.challenge, session.secret)
    if hmac ~= verify then
        skynet.error("session("..session.fd..") do verify error.")
        gateserver.closeclient(session.fd)
        return
    end
    session.proc = do_login
end

local function do_auth(session, msg, sz)
    -- base64encode(8 bytes randomkey) is 12 bytes.
    if sz == 12 then
        local cex = crypt.base64decode(netpack.tostring(msg, sz))
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

function handler.dissessionect(fd)
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