local skynet = require "skynet"


----------------------------------------------------------------------------

local function login(clisession, msgdata)
    local ok, msg = pcall(sproto.decode, clisession.proto(), "c2s_login", msgdata)
    if not ok then
        skynet.error("Parse proto of '.login' error. ")
        clisession:kick()
        return
    end
end

----------------------------------------------------------------------------

local handler = {}
local MSG = {}

function MSG.register()
    local REG = function(id, func) handler[id] = func end

    REG(10001, login)
end

function MSG.dispatch(clisession, msgid, msgdata)
    local f = handler[msgid]
    if f then f(clisession, msgdata) end
end

return MSG