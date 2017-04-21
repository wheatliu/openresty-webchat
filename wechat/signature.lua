local str = require "resty.string"
local ngx = ngx

local _M = {__version='0.1.0'}

_M.signature = function(nonce, timestamp, msg)
    local tmpTab = {nonce, tostring(timestamp), 'Das1w0yebu5hu0', msg}
    table.sort(tmpTab)
    local rawStr = table.concat(tmpTab)
    local sha1 = ngx.sha1_bin(rawStr)
    return str.to_hex(sha1)
end

return _M
