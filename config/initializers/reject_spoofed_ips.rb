# typed: false

# request.remote_ip can raise IpSpoofAttackError when it's first evaluated, which can be anywhere.
# ApplicationController tried to eagerly eval, but Lograge got in front of it, so this is earlier.
class RejectSpoofedIps
  MESSAGE = "You have some kind of weird, implausible VPN setup. If you are not doing something naughty, please contact the admin to start debugging."

  def initialize(app)
    @app = app
  end

  def call(env)
    ActionDispatch::Request.new(env).remote_ip
    @app.call(env)
  rescue ActionDispatch::RemoteIp::IpSpoofAttackError
    [400, {"content-type" => "text/plain"}, [MESSAGE]]
  end
end

Rails.application.config.middleware.insert_after ActionDispatch::RemoteIp, RejectSpoofedIps
