local sproto = require "sproto"
local socketdriver = require "socketdriver"
local netpack = require "netpack"
local crypt = require "crypt"
local lzc = require "lzc"

local proto

local session = {}

-- 定义协议
function session.proto(p)
    proto = p
end

-- 创建会话
function session.new(base)
    return setmetatable(base or {}, {__index = session})
end

-- 绑定套接字
function session:bindfd(fd, addr)
    self.fd = fd
    self.addr = addr
    return self
end

-- 绑定网关
function session:bindgate(gate)
    self.gate = gate
    return self
end

-- 绑定玩家对象
function session:bindplayer(player)
    player.clisession = self
    self.player = player
    return self
end

-- 获取玩家
function session:getplayer()
    return self.player
end

-- 验证玩家身份, 防止消息欺骗
function session:checkplayer(usrid)
    if not self.player then return nil end
    return self.player.usrid == usrid and self.player or nil
end

-- 根据协议序列化数据并发送
function session:send(msgid, msgname, data, compress)
    local ok, msg = pcall(sproto.encode, proto.proto, msgname, data)
    if not ok then return end
    if compress then msg = lzc.compress(msg) end
    ok, msg = pcall(sproto.encode, proto.wrap, "MessageWrap", {msgid = msgid, compress = compress, msgdata = msg})
    if not ok then return end
    self:sendraw(msg)
    return self
end

-- 发送原生数据
function session:sendraw(data)
    local ok, d = pcall(crypt.teaencode, self.secret, data)
    if not ok then return end
    socketdriver.send(self.fd, netpack.pack(d))
end

return session