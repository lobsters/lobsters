# typed: false

# Rails and Caddy both log this header as a top-level key .request_token to correlate requests
# between logs. Fun corner cases that definitely didn't burn hours of dev time:
#
# slow_query.log: if the query came from the console or a job the request_token is an empty string.
#
# joining action.log -> caddy.log
#  - Jobs to render and cache pages will log tokens that won't appear in caddy.log, but always have
#    remote_ip 127.0.0.1.
#
# joining caddy.log -> action.log
#  - If Caddy serves an asset, cached page, or bot rejection the request_token is empty string.
#  - If Rack::Attack rejects, the request doesn't reach a controller to generate a log line.
#  - If a controller raises an exception (usually RecordNotFound), config.exceptions_app routes it
#    back into our single routing table, generating a second log line with the same request_token.
#
# The Caddy -> Rails issues argue in favor of having Caddy generate, but it can only generate
# UUIDv4 IDs. I can't stand to look at those, don't want to write a module, and we'd lose anything
# Hatchbox has already compiled into Caddy.

# https://lobste.rs/about#queries - For guidance, here's a pair of log lines from a real query, the
# only change was that I replaced their real IP with 1.2.3.4.
#
# action.log is mostly useful for perf:
# {"method":"GET","path":"/","format":"html","controller":"HomeController","action":"index","status":200,"allocations":24731,"duration":43.94,"view":31.14,"db":0.37,"timestamp":"2026-10-17T21:02:02.922Z","request_token":"request_01m55tqx3re0n97zq3rha688z4","params":{},"exception":null,"exception_message":null,"remote_ip":"1.2.3.4","user_id":0,"username":"nobody"}
#
# caddy.log is mostly useful for traffic:
# {"level":"info","timestamp":"2026-10-17T21:02:02.926Z","logger":"http.log.access.disk-log","msg":"handled request","request":{"remote_ip":"1.2.3.4","remote_port":"56872","proto":"HTTP/3.0","method":"GET","host":"lobste.rs","uri":"/","headers":{"Accept-Encoding":["gzip, deflate, br, zstd"],"Priority":["u=0, i"],"User-Agent":["Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Mobile Safari/537.36"],"Cookie":["REDACTED"],"Accept-Language":["en-DE,en;q=0.9,de-DE;q=0.8,de;q=0.7,en-GB;q=0.6,en-US;q=0.5"],"Accept":["text/html,application/xhtml+xml,application/xml;q=0.9,image/jxl,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"],"Sec-Fetch-Site":["none"],"Sec-Ch-Ua-Mobile":["?1"],"Sec-Fetch-Dest":["document"],"Sec-Ch-Ua":["\"Google Chrome\";v=\"155\", \"Chromium\";v=\"155\", \"Not(A:Brand\";v=\"24\""],"Sec-Fetch-Mode":["navigate"],"Sec-Ch-Ua-Platform":["\"Android\""],"Sec-Purpose":["prefetch;prerender"],"Sec-Fetch-User":["?1"],"Upgrade-Insecure-Requests":["1"],"If-None-Match":["W/\"bc837aeb849fd2f47a20ba3a7e2a8bb8\""]},"tls":{"resumed":true,"version":772,"cipher_suite":4865,"proto":"h3","server_name":"lobste.rs"}},"bytes_read":0,"user_id":"","duration":0.056165818,"size":8577,"status":200,"resp_headers":{"X-Content-Type-Options":["nosniff"],"Via":["1.1 Caddy"],"Feature-Policy":["accelerometer 'none'; autoplay 'none'; ambient-light-sensor 'none'; camera 'none'; encrypted-media 'none'; fullscreen 'none'; geolocation 'none'; gyroscope 'none'; idle-detection 'none'; magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture 'none'; screen-wake-lock 'none'; serial 'none'; sync-xhr 'none'; usb 'none'; web-share 'none'"],"Content-Encoding":["zstd"],"Content-Type":["text/html; charset=utf-8"],"Strict-Transport-Security":["max-age=31536000","max-age=63072000; includeSubDomains; preload"],"Referrer-Policy":["strict-origin-when-cross-origin"],"Cache-Control":["max-age=0, private, must-revalidate"],"Content-Security-Policy":["default-src 'none'; connect-src 'self'; img-src 'self' data:; manifest-src 'self'; script-src 'self' 'nonce-lctrVbdI10+/O4up5rUqNQ=='; style-src 'self' 'unsafe-inline'"],"Link":["</application.css>; rel=preload; as=style; nopush,</system-system.css>; rel=preload; as=style; nopush,</application.js>; rel=modulepreload; as=script; nopush"],"Vary":["Accept-Encoding"],"Etag":["W/\"5843ce09d14b8dffc46b8ffa8e4eca48\""],"Set-Cookie":["REDACTED"],"X-Request-Token":["request_01m55tqx3re0n97zq3rha688z4"],"Date":["Sat, 17 Oct 2026 21:02:02 GMT"],"X-Permitted-Cross-Domain-Policies":["none"],"X-Frame-Options":["SAMEORIGIN"],"X-Xss-Protection":["0"]},"remote_ip":"1.2.3.4","request_token":"request_01m55tqx3re0n97zq3rha688z4"}

class XRequestToken < ActionDispatch::RequestId
  def make_request_id(_request_id)
    TypeID.new("request").to_s
  end
end

# X-Request-Id -> X-Request-Token
Rails.application.config.action_dispatch.request_id_header = "X-Request-Token"
Rails.application.config.middleware.swap ActionDispatch::RequestId, XRequestToken, header: Rails.application.config.action_dispatch.request_id_header
