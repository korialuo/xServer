local skynet = require "skynet"
local webclientlib = require "webclient"

local webclient = nil
local requests = nil

local function respond(request)
    if not request then return end
    if not request.response then return end
    local content, errmsg = webclient:get_respond(request.req)
    if not errmsg then
        request.response(true, true, content)
    else
        request.response(true, false, errmsg)
    end
end

local function query()
    while next(requests) do
        local finish_key = webclient:query()
        if finish_key then
            local request = requests[finish_key];
            xpcall(respond, function() end, request)
            webclient:remove_request(request.req)
            requests[finish_key] = nil
        else
            skynet.sleep(1)
        end
    end 
    requests = nil
end

local function request(url, get, post, no_reply)
    if get and type(get) == "table" then
        local i = 0
        for k, v in pairs(get) do
            url = string.format(
                "%s%s%s=%s", 
                url, 
                i == 0 and "?" or "&", 
                webclient:url_encoding(k), 
                webclient:url_encoding(v)
            )
            i = i + 1
        end
    end

    if post and type(post) == "table" then
        local data = {}
        for k, v in pairs(post) do
            table.insert(data, string.format(
                "%s=%s", 
                webclient:url_encoding(k), 
                webclient:url_encoding(v)
            ))
        end   
        post = table.concat(data , "&")
    end

    local req, key = webclient:request(url, post)
    if (not req) or (not key)  then
        return skynet.ret()
    end

    local resp = nil
    if not no_reply then
        resp = skynet.response()
    end

    if requests == nil then
        requests = {}
        skynet.fork(query)
    end

    requests[key] = {
        url = url, 
        req = req,
        response = resp,
    }
end

skynet.init(function()
    webclient = webclientlib.create()
end)

skynet.start(function()
    skynet.dispatch("lua", function(session, source, command, ...)
        if command == "request" then
            request(...)
        end
    end)
end)