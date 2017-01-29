local player = require "player"

local playermgr = {
    -- player map
    _players_id = {},  -- id --> player
    _players_fd = {}   -- fd --> player
}

-- 创建玩家对象
function playermgr.newplayer(res, token)
    return player.new(res, token)
end

-- 绑定会话
function playermgr.bindsession(player, clisession)
    playermgr._players_fd[clisession.fd] = player:bindsession(clisession)
    return player
end

-- 托管一个玩家
function playermgr.addplayer(player)
    if not playermgr._players_id[player.usrid] then
        playermgr._players_id[player.usrid] = player
    end
    return player
end

-- 移除一个玩家
function playermgr.removeplayer(clisession)
    local player = playermgr._players_fd[clisession.fd]
    if player then
        player.clisession = nil
        playermgr._players_fd[clisession.fd] = nil
    end
    return player
end

-- 根据玩家ID查询玩家
function playermgr.findplayerbyid(usrid)
    return playermgr._players_id[usrid]
end

-- 根据会话ID查询玩家
function playermgr.findplayerbyfd(fd)
    return playermgr._players_fd[fd]
end

return playermgr