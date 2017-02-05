local skynet = require "skynet"
local socket = require "socket"
local utils = require "utils"
require "skynet.manager"

local CMD = {}

function CMD.quit(argv)
    if argv[2] == nil then
        skynet.abort() 
        return true
    end
    local timeout = tonumber(argv[2])
    if not timeout then
        return false
    end
    skynet.timeout(math.modf(100 * timeout), function()
        skynet.abort()
    end)
    return true
end

function CMD.launch(argv)
    if #argv <= 3 then
        return false
    end
    if argv[2] == "lua" then
        skynet.newservice(argv[3], table.unpack(argv, 4))
    elseif argv[2] == "c" then
        skynet.launch(argv[3], table.unpack(argv, 4))
    else
        return false
    end
    return true
end

local function console_main_loop()
	local stdin = socket.stdin()
	socket.lock(stdin)
	while true do
        local cmdline = socket.readline(stdin, "\n")
        local argv = utils.strsplit(cmdline, ' ')
        if #argv > 0 then
            local c = argv[1]
            local f = CMD[c]
            if f then 
                local ret = f(argv)
                if not ret then 
                    skynet.error("Command '"..argv[1].."' execute error.") 
                else
                    skynet.error("Command '"..argv[1].."' execute success.")
                end 
            end
        end
	end
    socket.unlock(stdin)
end

skynet.start(function()
    skynet.fork(console_main_loop)
end)
