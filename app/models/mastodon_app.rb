# typed: false

# https://docs.joinmastodon.org/methods/apps/
class MastodonApp < ApplicationRecord
  validates :name, :client_id, :client_secret, presence: true

  # https://docs.joinmastodon.org/methods/oauth/
  def oauth_auth_url
    "https://#{name}/oauth/authorize?response_type=code&client_id=#{client_id}&scope=read:accounts&redirect_uri=" +
      CGI.escape(redirect_uri)
  end

  def redirect_uri
    "https://#{Rails.application.domain}/settings/mastodon_callback?instance=#{name}"
  end

  def register_app
    raise "already registered, delete and recreate" if client_id.present?

    s = Sponge.new
    url = "https://#{name}/api/v1/apps"
    res = s.fetch(
      url,
      :post,
      client_name: Rails.application.domain,
      redirect_uris: [
        "https://#{Rails.application.domain}/settings",
        redirect_uri
      ].join("\n"),
      scopes: "read:accounts",
      website: "https://#{Rails.application.domain}"
    )
    js = JSON.parse(res.body)
    if js && js["client_id"].present? && js["client_secret"].present?
      self.client_id = js["client_id"]
      self.client_secret = js["client_secret"]
      return save!
    end
    raise "registration failed, response was #{res.body}"
  end

  def token_and_user_from_code(code)
    s = Sponge.new
    res = s.fetch(
      "https://#{name}/oauth/token",
      :post,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri,
      grant_type: "authorization_code",
      code: code,
      scope: "read:account"
    )
    ps = JSON.parse(res.body)
    tok = ps["access_token"]

    if tok.present?
      headers = {"Authorization" => "Bearer #{tok}"}
      res = s.fetch(
        "https://#{name}/api/v1/accounts/verify_credentials",
        :get,
        nil,
        nil,
        headers
      ).body
      js = JSON.parse(res)
      if js && js["username"].present?
        return [tok, js["username"]]
      end
    end

    [nil, nil]
  end

  # https://docs.joinmastodon.org/methods/oauth/#revoke
  def revoke_token(token)
    return if token.blank?

    s = Sponge.new
    res = s.fetch(
      "https://#{name}/oauth/revoke",
      :post,
      client_id: client_id,
      client_secret: client_secret,
      token: token
    )
    ps = JSON.parse(res.body)
    if ps != {}
      Rails.logger.info "Unexpected failure revoking token from #{name}, response was #{res.body}"
    end
    ps == {}
  end

  def self.find_or_register(instance_name)
    name = sanitized_instance_name(instance_name)
    existing = find_by name: name
    return existing if existing.present?

    app = new name: name
    app.register_app
    app.save!
    app
  end

  # extract hostname from possible URL
  def self.sanitized_instance_name(instance_name)
    instance_name.delete_prefix "https://"
    instance_name.split("/").first
  end
end
