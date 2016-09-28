local skynet = require "skynet"
local mysql = require "mysql"

local args = table.pack(...)
assert(args.n >= 1)
local mode = assert(args[1])
local instance = tonumber(args[2] or 1)

local slaves = {}
local balance = 1
local database

local CMD = {}

function CMD.query(q)
    return database:query(q)
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

local function connect_db()
    database = mysql.connect({
        host = assert(skynet.getenv("db_address")),
        port = assert(tonumber(skynet.getenv("db_port"))),
        database = assert(skynet.getenv("db_name")),
        user = assert(skynet.getenv("db_user")),
        password = assert(skynet.getenv("db_password")),
        max_packet_size = assert(tonumber(skynet.getenv("db_maxpacketsz"))),
        on_connect = function(db)
            db:query("set charset utf8mb4")
        end
    })
    if not database then
        skynet.error("Failed to connect to database !")
    end
    skynet.error("Success to connect to database.")
end

if mode == "master" then
    skynet.start(function()
        -- launch slave service
        for _ = 1, instance do
            table.insert(slaves, skynet.newservice(SERVICE_NAME, "slave"))
        end
        -- dispatch message
        skynet.dispatch("lua", function(_, _, command, ...)
            skynet.ret(skynet.pack(dispatch_message(command, ...)))
        end)
    end)
elseif mode == "slave" then
    skynet.start(function()
        connect_db()
        skynet.dispatch("lua", function(_, _, command, ...)
            skynet.ret(skynet.pack(dispatch_message(command, ...)))
        end)
    end)
end