Rack::Attack.safelist('localhost') do |req|
  '127.0.0.1' == req.ip || '::1' == req.ip
end

Rack::Attack.throttle("25 requests per second", limit: 25, period: 1) do |request|
  request.ip
end
