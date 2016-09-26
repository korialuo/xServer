local skynet = require "skynet"

local CMD = {}

function CMD.dipatchmsg(msg)

end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(...)))
    end)
end)
