# typed: false

# Hi, what brings you here?

# RSS reader with many of our feeds? You can combine separate tag feeds like this:
# instead of /t/c.rss and /t/python.rss, check /t/c,python.rss

# You're trying to figure out something about site activity? You can just write a database query:
# https://lobste.rs/about#queries

# You're experimenting with writing a scraper of some sort? I appreciate that you're a fan of the
# site, but please don't do that to a prod service run by hobbyists. C'mon.

# You're a commercial service? Slow down or email me. pushcx@ our domain.

# Otherwise, check the RateLimit headers you get back. RateLimit-Reset tells you how many seconds to
# wait if you get a 429.

Rack::Attack.safelist("localhost") do |req|
  req.ip == "127.0.0.1" || req.ip == "::1"
end

# these will kick in way too early if serving assets via rack, so don't
Rack::Attack.throttle("rate 1 second", limit: 4, period: 1) { |r| r.ip }
Rack::Attack.throttle("rate 1 minute", limit: 30, period: 60) { |r| r.ip }
Rack::Attack.throttle("rate 10 minutes", limit: 100, period: 600) { |r| r.ip }
Rack::Attack.throttle("rate 1 hour", limit: 400, period: 3600) { |r| r.ip }

# there's attackers enumeratng usernames, mostly via Tor
Rack::Attack.throttle("user enumerator", limit: 30, period: 300) do |request|
  request.ip if request.path.starts_with?("/u/") || request.path.starts_with?("/~")
end
# at some point they'll proceed to testing credentials
Rack::Attack.throttle("login", limit: 4, period: 60) do |request|
  request.ip if request.post? &&
    request.path.start_with?("/login", "/login/set_new_password")
end

Rack::Attack.throttle("log4j probe", limit: 1, period: 1.week.to_i) do |request|
  request.ip if request.user_agent.try(:include?, "${")
end

Rack::Attack.throttle("SEO/spam tools", limit: 1, period: 1.week.to_i) do |request|
  request.ip if request.user_agent.try(:include?, "www.semrush.com/bot") ||
    request.user_agent.try(:include?, "webmeup-crawler.com") ||
    request.user_agent.try(:include?, "ChatGPT-User") ||
    request.user_agent.try(:include?, "mentions.us") ||
    request.user_agent.try(:include?, "axios")
end

Rack::Attack.throttle("a particular bad bot", limit: 1, period: 1.week.to_i) do |request|
  request.ip if request.path.start_with?("//avatars")
end

# explain the throttle
Rack::Attack.throttled_response_retry_after_header = true
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"]
  now = match_data[:epoch_time]

  headers = {
    "RateLimit-Limit" => match_data[:limit].to_s,
    "RateLimit-Remaining" => "0",
    "RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s
  }

  [429, headers, ["Throttled, sleep(1) between hits; more in config/initializers/rack_attack.rb\n"]]
end
