local accessToken = require "wechat.accessToken"
local token = ngx.shared.token
local ngx = ngx
local work_id = ngx.worker.id()
local max_retry = 5
local retry_time = 1
local get_access_token
local refresh_accesstoken

if work_id > 0 then return end

get_access_token = function()
    if retry_time > 5 then
        ngx.log(ngx.ERR, 'Request access token failed!')
        return
    end

    local access_token = accessToken.new()
    if not access_token then
        ngx.log(ngx.ERR, 'Request access token failed! retry...', retry_time)
        retry_time = retry_time + 1
        return get_access_token()
    end

    ngx.log(ngx.ERR, 'request new access token, token: ', access_token, ' time: ', ngx.localtime())
    return access_token;
end

local init_accesstoken = function()
    local access_token = get_access_token()
    ngx.log(ngx.ERR, access_token, access_token)
    if not access_token then
        return
    end

    local succ, err, forcible = token:set('access_token', access_token)
    if not succ then
        ngx.log(ngx.ERR, 'refresh access token cache err: ', err)
        return
    end
    ngx.log(ngx.ERR, 'Refresh access token cache success, token: '..access_token, ' time: '..ngx.localtime())
end

refresh_accesstoken = function()
    init_accesstoken()
    ngx.timer.at(7000, refresh_accesstoken)
end

ngx.timer.at(1, init_accesstoken)
ngx.timer.at(7000, refresh_accesstoken)
