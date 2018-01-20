local skynet = require "skynet"
local socket = require "skynet.socket"

local rds_ip, rds_port, listen_ip, listen_port = ...

local listen_socket
local rds_sock_pool = {}
local cli_sock_pool = {}


local function cli_loop(clisock)
    local rdssock = rds_sock_pool[clisock]
    if rdssock == nil then return end
    socket.start(clisock)
    local data = socket.read(clisock)
    while data do
        socket.lwrite(rdssock, data)
        data = socket.read(clisock)
    end
    socket.close(rdssock)
    cli_sock_pool[rdssock] = nil
    rds_sock_pool[clisock] = nil
end

local function rds_loop(rdssock)
    local clisock = cli_sock_pool[rdssock]
    if clisock == nil then return end
    local data = socket.read(rdssock)
    while data do
        socket.lwrite(clisock, data)
        data = socket.read(rdssock)
    end
    socket.close(clisock)
    cli_sock_pool[rdssock] = nil
    rds_sock_pool[clisock] = nil
end

local function accept(clisock, ip)
    local rdssock = socket.open(rds_ip, tonumber(rds_port))
    rds_sock_pool[clisock] = rdssock
    cli_sock_pool[rdssock] = clisock
    skynet.fork(cli_loop, clisock)
    skynet.fork(rds_loop, rdssock)
end

skynet.start(function()
    listen_socket = socket.listen(listen_ip, tonumber(listen_port))
    socket.start(listen_socket, accept)
end)
