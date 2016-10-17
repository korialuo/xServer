local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local socketdriver = require "socketdriver"
local netpack = require "netpack"
local crypt = require "crypt"

local chatsvr = assert(...)
local connections = {}
local handler = {}
local CMD = {}

local function do_cleanup(fd)
    local conn = connections[fd]
    if conn then connections[fd] = nil end
    gateserver.closeclient(fd)
end

local function do_dispatchmsg(conn, msg, sz)
    return skynet.call(chatsvr, "lua", "dispatchmsg", conn, netpack.tostring(msg, sz))
end

local function do_verify(conn, msg, sz)
    local hmac = crypt.base64decode(netpack.tostring(msg, sz))
    local verify = crypt.hmac64(conn.challenge, conn.secret)
    if hmac ~= verify then
        skynet.error("Connection("..fd..") do verify error.")
        do_cleanup(conn.fd)
    end
    conn.proc = do_dispatchmsg
end

local function do_auth(conn, msg, sz)
    if sz == 8192 then
        local cex = crypt.base64decode(netpack.tostring(msg, sz))
        local skey = crypt.randomkey()
        local sex = crypt.dhexchange(skey)
        conn.secret = crypt.dhsecret(cex, skey)
        socketdriver.send(conn.fd, netpack.pack(crypt.base64encode(sex)))
        conn.proc = do_verify
    else
        skynet.error("Connection("..conn.fd..") do auth error.")
        do_cleanup(conn.fd)
    end
end

local function do_handshake(conn)
    conn.challenge = crypt.randomkey()
    socketdriver.send(conn.fd, netpack.pack(crypt.base64encode(conn.challenge)))
    conn.proc = do_auth
end

function handler.connect(fd, addr)
    local conn = {
        fd = fd,
        addr = addr,
        challenge = nil,
        secret = nil,
        proc = nil
    }
    connections[fd] = conn
    gateserver.openclient(fd)
    do_handshake(conn)
end

function handler.disconnect(fd)
    do_cleanup(fd)
end

function handler.error(fd, msg)
    skynet.error("Connection("..fd..") error: "..msg)
    do_cleanup(fd)
end

function handler.message(fd, msg, sz)
    local conn = connections[fd]
    if conn then
        conn.proc(conn, msg, sz)
    else
        skynet.error("Unknown connection("..fd..").");
        do_cleanup(fd)
    end
end

function handler.command(cmd, source, ...)
    local f = assert(CMD[cmd])
    return f(...)
end

function handler.warning(fd, size)
    skynet.error("Connection("..fd..") send buffer warning: high water marks !")
end

-- start a gatesvr service
gateserver.start(handler)