# typed: false

class XRequestToken < ActionDispatch::RequestId
  def make_request_id(_request_id)
    TypeID.new("request").to_s
  end
end

# X-Request-Id -> X-Request-Token
Rails.application.config.action_dispatch.request_id_header = "X-Request-Token"
Rails.application.config.middleware.swap ActionDispatch::RequestId, XRequestToken, header: Rails.application.config.action_dispatch.request_id_header
