local skynet = require "skynet"
local socketdriver = require "socketdriver"
local crypt = require "crypt"
local cjson = require "cjson"

local logindb = assert(tonumber(...))
skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring
}

local users = {}  -- usrid --> user info: {usrid, conn, svrid}

local MSG = {}

function MSG.login(conn, msg)
    local user, server, password = msg.u, msg.s, msg.p
    local q = "CALL login('"..user.."', "..password.."');"
    q = skynet.call(logindb, "lua", "query", q)
    -- TODO: verify the user and passoword, then return to client
end

skynet.start(function()
    skynet.dispatch("client", function(session, source, conn, msg, ...)
        local ok, msgdata = pcall(crypt.desdecode, conn.secret, crypt.base64decode(msg))
        if not ok then skynet.error("Des decode client message error. fd: "..conn.fd) return end
        ok, msgdata = pcall(cjson.decode, msgdata)
        if ok then
            local m = msgdata.__m
            if m and type(m) == "string" then
                local f = MSG[m]
                if not f then skynet.error("Unregisted client message: "..m) else f(conn, msgdata) end
            end
        else
            skynet.error("Parse client message error. fd: "..conn.fd)
        end
    end)
end)