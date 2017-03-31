local player = {
    -- Status
    STATUS_LOGINED = 1,
    STATUS_VERIFIED = 2,
}

-- 创建玩家
function player.new(res, token)
    return setmetatable({
        clisession = nil,
        usrid = res.usrid,
        account = res.account,
    }, {__index = player})
end

-- 绑定会话
function player:bindsession(session)
    self.clisession = session
    return self
end

-- 根据协议序列化数据并发送
function player:send(msgid, msgname, data, compress)
    if self.clisession then
        self.clisession:send(msgid, msgname, data, compress)
    end
end

-- 发送原生数据
function player:sendraw(data)
    if self.clisession then
        self.clisession:sendraw(data)
    end
end

return player