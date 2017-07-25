local skynet = require "skynet"


----------------------------------------------------------------------------


----------------------------------------------------------------------------

local handler = {}
local MSG = {}

function MSG.register()
    local REG = function(id, func) handler[id] = func end

end

function MSG.dispatch(clisession, msgid, msgdata)
    local f = handler[msgid]
    if f then f(clisession, msgdata) end
end

return MSG