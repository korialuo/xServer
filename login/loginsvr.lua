local skynet = require "skynet"
local crypt = require "crypt"

local CMD = {}

function CMD.login(conn, msg)
    local token = crypt.base64decode(crypt.desdecode(conn.secret, msg))
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)