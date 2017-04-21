local str = require "resty.string"
local message = require 'wechat.message'
local setmetatable = setmetatable
local type = type
local ngx_var = ngx.var

local _M = { _VERSION = '0.1.0'}

-- mp access
_M.get = function()

    local req = {
        query = ngx.req.get_uri_args(),
        rawBody = ngx.req.get_body_data()
    }
    local signature = req.query.signature
    local timestamp = req.query.timestamp
    local nonce = req.query.nonce
    local echostr = req.query.echostr
    if not (signature and timestamp and nonce and echostr) then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    local tmpTab = {nonce, timestamp, 'Das1w0yebu5hu0'}
    table.sort(tmpTab)
            local rawStr = table.concat(tmpTab)
    local sha1 = ngx.sha1_bin(rawStr)
    local sig = str.to_hex(sha1)
            ngx.log(ngx.ERR, 'rawStr: ', rawStr, ' signature: ', signature, ' sig: ', sig)
    if sig == signature then
        ngx.say(echostr)
    else
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

_M.post = function()
    local req = {
        query = ngx.req.get_uri_args(),
        rawBody = ngx.req.get_body_data()
    }
    local data = req.rawBody
    local msg = message.parse(data)
    local encrypted = msg.Encrypt
    if encrypted then
        msg = message.parseEncryptMsg(encrypted)
    end
    if not msg then return ngx.say('success') end
    local typ = msg.MsgType
    if not typ or not message[typ] then
        return ngx.say('')
    end
    local nonce = req.query.nonce
    local rtn = message[typ](msg, nonce, encrypted)
    ngx.say(rtn)
end

return _M
