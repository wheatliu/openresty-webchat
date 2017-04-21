require "pack"
local expat = require 'expat'
local bpack = string.pack
local bunpack = string.unpack
local aes = require("resty.aes")
local str = require "resty.string"
local resty_random = require "resty.random"
local unique = require("utils.unique")
local msgTemp = require 'wechat.template'
local signature = require 'wechat.signature'
local redis = require('iredis')
local tasks = require('wechat.tasks')
local geo = require "utils.geo"

local aesKey = ngx.decode_base64('blabla'..'=')
local appId = 'balbla'


local _M = {__version = '0.1.0'}

local gen_randon_str = function()
     local random = resty_random.bytes(8)
     ngx.log(ngx.ERR, 'random: ', str.to_hex(random))
     return str.to_hex(random)
end


_M.parse = function(s)
    local msg = {}
    ngx.log(ngx.ERR, 'xml: ', s)
    local data = expat.treeparse({string=s})
    for k, v in pairs(data.children[1].tags) do
        msg[k] = v.cdata
    end
    return msg
end

_M.parseEncryptMsg = function(encrypted)
    local cryptor = aes:new(aesKey, nil, aes.cipher(256, "cbc"), {iv=aesKey:sub(1,16)}, nil, 0)
    local text = cryptor:decrypt(ngx.decode_base64(encrypted))
    local err, msg_len = bunpack(text:sub(17, 20), '>I')
    local padding_length = string.byte(text:sub(-1))
    if padding_length < 1 or padding_length > 32 then
        padding_length = 0;
    end
    ngx.log(ngx.ERR, 'padding:', padding_length)
    local xml = text:sub(21, 20 + msg_len)
    local msg_appId = text:sub(21 + msg_len, -padding_length - 1)
    if  msg_appId ~= appId then
       ngx.log(ngx.ERR, 'invaild appId:', msg_appId)
       return nil
    end
    return _M.parse(xml)
end

local encrypt_msg = function(plain_msg, nonce)
    local now = ngx.time()
    local cryptor = aes:new(aesKey, nil, aes.cipher(256, "cbc"), {iv=aesKey:sub(1,16)}, nil, 0)
    local encrypt_text = gen_randon_str()..bpack('>I', #plain_msg)..plain_msg..appId
    local block_size = 32;
    local padding_size = block_size - #encrypt_text % block_size
    local padding_encrypt_text = encrypt_text..string.rep(string.char(padding_size), padding_size)
    local encrypted_msg_body = cryptor:encrypt(padding_encrypt_text)
    ngx.log(ngx.ERR, 'body',  encrypted_msg_body)
    encrypted_msg_body = ngx.encode_base64(encrypted_msg_body)
    ngx.log(ngx.ERR, 'encrypted_msg_body: ', encrypted_msg_body)
    local sig = signature.signature(nonce, now, encrypted_msg_body)
    local encrypted_msg = string.format(msgTemp.encrypted_text, encrypted_msg_body, sig, now, nonce)
    ngx.log(ngx.ERR, encrypted_msg)
    return encrypted_msg
end

local sendText = function(text, send_to, nonce, encrypt)
    local now = ngx.time()
    local plain_msg = string.format(msgTemp.text, send_to, now, text, unique.nextId())
    ngx.log(ngx.ERR, 'plain_msg: ', plain_msg)
    if not encrypt then
        return plain_msg
    end
    local data = encrypt_msg(plain_msg, nonce)
    ngx.log(ngx.ERR, 'data:', data)
    return data
end

_M.text = function(msg, nonce, encrypt)
    local text = msg.Content
    local send_to = msg.FromUserName
    local data = sendText(text, send_to, nonce, encrypt)
    return data
end

_M.LOCATION = function(msg)
    ngx.log(ngx.ERR, 'hey')
    local from = msg.FromUserName
    local latitude = msg.Latitude
    local longitude = msg.Longitude
    ngx.log(ngx.ERR, from, latitude, longitude)
    local co = ngx.thread.spawn(geo.record_user_geo, from, latitude, longitude)
    return 'success'
end


_M.event = function(msg, nonce, encrypt)
    local from_user = msg.FromUserName
    local msg_event = msg.Event
    local handler = _M[msg_event] 
    if handler then return handler(msg) end
    if msg_event ~= 'CLICK' then return '' end
    local event_key = msg.EventKey
    if event_key ~= 'whether_bj' then return '' end
    local rds = redis:new()

    local res, err = rds:hmget(from_user, 'geo', 'latitude', 'longitude')
    if err then return sendText(err, from_user, nonce, encrypt) end
    if not res then return sendText('系统未查到您的地理信息，请先发送您的地理位置后再次获取天气信息', from_user, nonce, encrypt) end
    local co = ngx.thread.spawn(tasks.push_weather_msg,  from_user, res)
    return 'success'
end
return _M
