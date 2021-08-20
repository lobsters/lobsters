# if you are looking at this file because your RSS reader is triggering the
# rate-limiting, you can replace separate checks of /t/c.rss and /t/python.rss
# with a single check of /t/c,python.rss (you can add many tags)


Rack::Attack.safelist('localhost') do |req|
  '127.0.0.1' == req.ip || '::1' == req.ip
end

# mitigating https://lobste.rs/s/8kxcvy - will post a comment there with more
# info in a few hours
Rack::Attack.throttle("1 request per 4 seconds", limit: 1, period: 4, &:ip)

# this will kick in way too early if serving assets via rack
Rack::Attack.throttle("5 requests per second", limit: 5, period: 1, &:ip)

# we ask scrapers to sleep 1s between hits
Rack::Attack.throttle("60 requests per minute", limit: 60, period: 60, &:ip)

# there's an attacker enumeratng usernames via Tor
Rack::Attack.throttle("user enumerator", limit: 30, period: 300) do |request|
  request.ip if request.path.starts_with? '/u/'
end
# at some point they'll proceed to testing credentials
Rack::Attack.throttle("login", limit: 4, period: 60) do |request|
  request.ip if request.post? &&
                (request.path == '/login' || request.path == '/login/set_new_password')
end

# explain the throttle
Rack::Attack.throttled_response_retry_after_header = true
Rack::Attack.throttled_response = lambda do |env|
  match_data = env['rack.attack.match_data']
  now = match_data[:epoch_time]

  headers = {
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s,
  }

  [429, headers, ["Throttled, sleep(1) between hits; more in config/initializers/rack_attack.rb\n2021-08-20 - sorry for the inconvenience, I had to make rate limiting stricter and will post a comment in https://lobste.rs/s/8kxcvy n a few hours"]]
end
