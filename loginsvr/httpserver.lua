local skynet = require "skynet"
local urllib = require "http.url"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local socket = require "socket"


local args = table.pack(...)
assert(args.n >= 1)
local mode = assert(args[1])
local nslave = assert(tonumber(args[2] or 1))
local slaves = {}
local balance = 1


local function response(fd, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
    if not ok then
        skynet.error(string.format("httpd write response failed. fd(%d), %s", fd, err))
    end
end

local CMD = {}

function CMD.request(fd)
    socket.start(fd)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
    if code then
        if code ~= 200 then
            response(fd, code)
        else
            local path, query = urllib.parse(url)
            if query then
                local q = urllib.parse_query(query)
                for k, v in pairs(q) do
                
                end
            end
            response(fd, code, "OK")
        end
    else
        if url == sockethelper.socket_error then
            skynet.error("dispatch http request error. socket closed.")
        else
            skynet.error("dispatch https request error. "..url)
        end
    end
    socket.close(fd)
end

local function dispatch_message(cmd, ...)
    if mode == "slave" then
        local f = assert(CMD[cmd])
        return f(...)
    end
    return nil
end

skynet.dispatch("lua", function(session, source, command, ...)
    skynet.ret(skynet.pack(dispatch_message(command, ...)))
end)

skynet.start(function()
    if mode == "master" then
        for i = 1, nslave do
            local slv = skynet.newservice(SERVICE_NAME, "slave")
            table.insert(slaves, slv)
        end
        local serverfd = socket.listen("localhost", "8080")
        socket.start(serverfd, function(fd, addr)
            local slv = slaves[balance]
            balance = balance % nslave + 1
            skynet.call(slv, "lua", "request", fd)
        end)
    elseif mode == "slave" then

    else
        skynet.exit() 
    end
end)