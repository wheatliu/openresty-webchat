local http = require "resty.http"
local json = require "cjson.safe"
local redis = require "iredis"
local google_token = 'blabla'

local _M = {__version='0.1.0'}

_M.get_address_from_google = function(x, y)
    local endpoint = string.format('https://maps.googleapis.com/maps/api/geocode/json?latlng=%s,%s&language=zh-CN&key=%s', x, y, google_token)
    ngx.log(ngx.ERR, 'endpoint: ', endpoint)
    local httpC = http.new()
    httpC:set_timeout(2*1000)
    local res, err = httpC:request_uri(endpoint, {
        ssl_verify=false
    })

    if not res then
        ngx.log(ngx.ERR, "failed to request: ", err)
        return
    end
    ngx.log(ngx.ERR, res.status)
    local body = json.decode(res.body)
    if body then return body.results[1] end
end

_M.record_user_geo = function(from, x, y)
    ngx.log(ngx.ERR, 'record user:')
    ngx.log(ngx.ERR, from, x, y)
    local address = _M.get_address_from_google(x, y) or ''
    local rds= redis:new()
    local res, err = rds:hmset(from, 'geo', address.formatted_address, 'latitude', x, 'longitude', y) 
    if err then 
        ngx.log(ngx.ERR, 'set geo err:', err)
        return
    end
    ngx.log(ngx.ERR, 'set geo: address->', address.formatted_address, 'latitude->', x, 'longitude->',y)
    return
end
return _M
