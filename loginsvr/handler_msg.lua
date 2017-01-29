local skynet = require "skynet"

local MSG = {}

function MSG.login(clisession, package, proto)
    local ok, msg = pcall(sproto.decode, proto.c2s, "login", package)
    if not ok then
        skynet.error("Parse proto of '.login' error. ")
        skynet.call(clisession.gate, "lua", "kick", clisession.fd)
        return
    end
end

return MSG