local skynet = require "skynet"

local MSG = {}

function MSG.login(clisession, msgdata, proto)
    local ok, msg = pcall(sproto.decode, proto, "c2s_login", msgdata)
    if not ok then
        skynet.error("Parse proto of '.login' error. ")
        skynet.call(clisession.gate, "lua", "kick", clisession.fd)
        return
    end
end

return MSG