local http = require "resty.http"
local json = require "cjson.safe"
local geo = require 'utils.geo'
local weather = require "utils.weather"
local template = require "wechat.template"
local token = ngx.shared.token

local _M = {__version='0.1.0'}

 _M.push_weather_msg = function(from, geo)
    local x = geo[2]
    local y = geo[3]
    local address = geo[1]
    ngx.log(ngx.ERR, address)
    local weather_info = weather.get_weather_info_from_darksky(x, y)
    local data = string.format(template.weather_text, address,
                                weather_info.summary,
                                (weather_info.temperature - 32)*5/9,
                                (weather_info.humidity) * 100,
                                weather_info.windSpeed,
                                weather_info.visibility or '暂无',
                                weather_info.dewPoint,
                                weather_info.pressure,
                                (weather_info.cloudCover) * 100)
    ngx.log(ngx.ERR, 'weather data ---->', data)
    local body = {touser = from, msgtype = "text", text = {content = data}}
    body = json.encode(body)
    local access_token = token:get('access_token')
    local endpoint = string.format('https://api.weixin.qq.com/cgi-bin/message/custom/send?access_token=%s', access_token)
    local httpC = http.new()
    httpC:set_timeout(3*1000)
    local res, err = httpC:request_uri(endpoint, {
        method = 'POST',
        body = body,
        ssl_verify = false,
        headers = {
          ["Content-Type"] = "application/json",
        }
    })

    if not res then
        ngx.log(ngx.ERR,"failed to request: ", err)
        return
    end
    ngx.log(ngx.ERR, 'rsp: ->', res.body)
end

return _M
