require 'openssl/hmac'
require 'json'

class WebHooksController < ApplicationController
  def web_hook
    web_hook_id = request.headers['X-Web-Hook-Id']

    return head :bad_request if web_hook_id != Aqora.web_hook_id

    signature = request.headers['X-Signature']
    body = request.body.read
    digest = OpenSSL::HMAC.hexdigest(
      'SHA256',
      Aqora.secret,
      body
    )

    return head :unauthorized unless signature == digest

    event = JSON.parse(body)
    id = event['id']
    type = event['event']

    if type == 'user_updated'
      user = User.find_by(aqora_id: id)
      token, aqora_user = Aqora.oauth_refresh(user.aqora_oauth_token)
      user.update!(
        aqora_oauth_token: token,
        username: aqora_user.username,
        email: aqora_user.email,
        homepage: aqora_user.website,
        about: aqora_user.bio,
        github_username: aqora_user.github
      )
    elsif type == 'user_deleted'
      user = User.find_by(aqora_id: id)
      user.delete!
      InactiveUser.disown_all_by_author! user
    end

    render json: { message: "Processed #{type} for #{id}" }
  end
end
