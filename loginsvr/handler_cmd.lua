local sessionmgr = require "sessionmgr"
local cluster = require "skynet.cluster"

local CMD = {}

function CMD.connect(source, clisession, node)
    local gatesvr = cluster.proxy(node, ".gatesvr")
    local cs = sessionmgr.newsession(clisession)
    sessionmgr.addsession(cs):bindgate(gatesvr)
end

function CMD.disconnect(gatesvr, clisession)
    local t = type(clisession)
    if t == "table" then
        sessionmgr.removesession(clisession)
    elseif t == "number" then
        local cs = sessionmgr.find(clisession)
        if cs then sessionmgr.removesession(cs) end
    end
end

return CMD