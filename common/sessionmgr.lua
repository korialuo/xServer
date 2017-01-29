local session = require "session"

local sessionmgr = {
    sessions = {}       -- fd --> session
}

-- 基于基本会话信息创建会话对象
function sessionmgr.newsession(base)
    return session.new(base)
end

-- 添加会话到管理列表
function sessionmgr.addsession(session)
    sessionmgr.sessions[session.fd] = session
    return session
end

-- 从管理列表中移除会话
function sessionmgr.removesession(session)
    sessionmgr.sessions[session.fd] = nil
    return session
end

-- 根据套接字句柄查找会话
function sessionmgr.find(fd)
    return sessionmgr.sessions[fd]
end

return sessionmgr