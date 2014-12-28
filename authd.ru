require ::File.expand_path('../config/environment',  __FILE__)
require 'rack/reverse_proxy'

class Authd
  def initialize
    config = Rails.application.config
    key_generator = ActiveSupport::KeyGenerator.new(config.secret_key_base, iterations: 1000)
    secret = key_generator.generate_key(config.action_dispatch.encrypted_cookie_salt)
    sign_secret = key_generator.generate_key(config.action_dispatch.encrypted_signed_cookie_salt)
    @encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret)
    @yxorp = Rack::ReverseProxy.new do
      reverse_proxy(//, 'http://localhost:9000')
    end
  end

  def maybe_db_session_token_of(data)
    @encryptor.decrypt_and_verify(data)['u']
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    data = request.cookie_jar['lobster_trap']
    maybe = maybe_db_session_token_of(data)
    if maybe
      env['HTTP_X_FROM_AUTHD'] = maybe
    end
    @yxorp.call(env)
  end
end

run Authd.new
