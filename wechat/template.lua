local userName = 'gh_9d341bcce201'

local _M = {
    text = [=[<xml><ToUserName><![CDATA[%s]]></ToUserName><FromUserName><![CDATA[gh_9d341bcce201]]></FromUserName><CreateTime>%d</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[%s]]></Content><MsgId>%s</MsgId></xml>]=],
    encrypted_text = [=[<xml><Encrypt><![CDATA[%s]]></Encrypt><MsgSignature><![CDATA[%s]]></MsgSignature><TimeStamp>%s</TimeStamp><Nonce><![CDATA[%s]]></Nonce></xml>]=],
    weather_text = [=[
位置: %s
天气情况: %s
温度: %.1f°
湿度: %s
风速: %s km/h
能见度: %s km
露点: %s°
气压: %s/hPa
云量: %s
    ]=]
}

return _M
