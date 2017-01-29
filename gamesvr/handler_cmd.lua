local sessionmgr = require "sessionmgr"

local CMD = {}

function CMD.disconnect(clisession)
    sessionmgr.removesession(clisession)
end

return CMD