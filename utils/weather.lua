local http = require "resty.http"
local json = require "cjson.safe"
local darksky_token = 'balbla'

local _M = {__version='0.1.0'}

_M.get_weather_info_from_darksky = function(x, y)
    local endpoint = string.format('https://api.darksky.net/forecast/394c14c4078f555a913dd15264d5b247/%s,%s?lang=zh&exclude=[daily,hourly,flags]', x, y)
    ngx.log(ngx.ERR, 'end point', endpoint)
    local httpC = http.new()
    httpC:set_timeout(3*1000)
    local res, err = httpC:request_uri(endpoint, {
        ssl_verify=false
    })

    if not res then
        ngx.log(ngx.ERR,"failed to request: ", err)
        return
    end
    ngx.log(ngx.ERR, res.body)
    local body = json.decode(res.body)
    local data = {

    }
    if body then return body.currently end
end

return _M
