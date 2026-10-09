# typed: false

# Rails and Caddy both log this header as a top-level key .request_token to correlate requests
# between logs. Fun corner cases that definitely didn't burn hours of dev time:
#
# slow_query.log: if the query came from the console or a job the request_token is an empty string.
#
# joining action.log -> caddy.log
#  - Jobs to render and cache pages will log tokens that won't appear in caddy.log
#
# joining caddy.log -> action.log
#  - If Caddy serves an asset, cached page, or bot rejection the request_token is empty string.
#  - If Rack::Attack rejects, the request doesn't reach a controller to generate a log line.
#  - If a conrtoller raises an exception (usually RecordNotFound), config.exceptions_app routes it
#    back into our single routing table, generating a second log line with the same request_token.
#
# The Caddy -> Rails issues argue in favor of having Caddy generate, but it can only generate
# UUIDv4 IDs. I can't stand to look at those, don't want to write a module, and we'd lose anything
# Hatchbox has built into Caddy already.

class XRequestToken < ActionDispatch::RequestId
  def make_request_id(_request_id)
    TypeID.new("request").to_s
  end
end

# X-Request-Id -> X-Request-Token
Rails.application.config.action_dispatch.request_id_header = "X-Request-Token"
Rails.application.config.middleware.swap ActionDispatch::RequestId, XRequestToken, header: Rails.application.config.action_dispatch.request_id_header
