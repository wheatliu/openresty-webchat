local http = require "resty.http"
local json = require "cjson.safe"

_M = {__version='0.1.0'}

function _M.new()
    local access_token_url = 'https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=blabla&secret=blabla'
    -- local url = string.format(access_token_url, config.appId, config.secret)
    local httpC = http.new()
    httpC:set_timeout(3*1000)
    local res, err = httpC:request_uri(access_token_url, {
        ssl_verify=false
    })

    if not res then
        ngx.log(ngx.ERR, "failed to request: ", err)
        return
    end

    print(res.status)
    local body = json.decode(res.body)
    if body then return body.access_token end
end

return _M
