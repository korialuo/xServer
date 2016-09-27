local skynet = require "skynet"
local crypt = require "crypt"

local args = table.pack(...)
assert(args.n >= 2)
local mode = assert(args[1])
local logindb = assert(args[2])
local instance = args[3] or 1

local slaves = {}
local balance = 1

local users = {}  -- usrid --> user info: {usrid, conn, svrid}

local CMD = {}

function CMD.login(conn, msg)
    -- the token is base64(user)@base64(server):base64(password)
    local token = crypt.desdecode(conn.secret, crypt.base64decode(msg))
    local user, server, password = string.match(token, "([^@]+)@([^:]+):(.+)")
    user = crypt.base64decode(user)
    server = crypt.base64decode(server)
    password = crypt.base64decode(password)
    local q = "CALL login('"..user.."', "..password.."');"
    q = skynet.call(logindb, "lua", "query", q)

    -- TODO: verify the user and passoword, then alloc the usrid and return to gateserver
end

function CMD.logout(usrid)
    -- TODO: cleanup binded user info
end

local function dispatch_message(cmd, ...)
    if mode == "master" then
        local slv = slaves[balance]
        balance = balance + 1
        if balance > instance then
            balance = 1
        end
        return skynet.call(slv, "lua", cmd, ...)
    elseif mode == "slave" then
        local f = assert(CMD[cmd])
        return f(...)
    end
end

if mode == "master" then
    skynet.start(function()
        -- launch slave service
        for _ = 1, instance do
            table.insert(slaves, skynet.newservice(SERVICE_NAME, "slave", logindb))
        end
        -- dispatch message
        skynet.dispatch("lua", function(_, _, command, ...)
            skynet.ret(skynet.pack(dispatch_message(command, ...)))
        end)
    end)
elseif mode == "slave" then
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, command, ...)
            skynet.ret(skynet.pack(dispatch_message(command, ...)))
        end)
    end)
end