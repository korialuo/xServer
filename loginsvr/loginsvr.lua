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

local users = {}  -- usrid --> user info: {usrid, session, svrid}

local MSG = {}

function MSG.login(clisession, msg)
    local user, server, password = msg.u, msg.s, msg.p
    local q = "CALL login('"..user.."', "..password.."');"
    q = skynet.call(logindb, "lua", "query", q)
    -- TODO: verify the user and passoword, then return to client
end

skynet.start(function()
    skynet.dispatch("client", function(session, source, clisession, msg, ...)
        local ok, msgdata = pcall(cjson.decode, msg)
        if ok then
            local m = msgdata.__m
            if m and type(m) == "string" then
                local f = MSG[m]
                if not f then skynet.error("Unregisted client message: "..m) else f(clisession, msgdata) end
            end
        else
            skynet.error("Parse client message error. fd: "..clisession.fd)
        end
    end)
end)