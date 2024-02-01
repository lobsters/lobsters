# typed: false

class Mastodon
  def self.enabled?
    true
  end

  def self.token_and_user_from_code(instance, code)
    mastodon_instance = MastodonInstance.find_by(name: instance)
    client_id = mastodon_instance.client_id
    client_secret = mastodon_instance.client_secret
    s = Sponge.new
    res = s.fetch(
      "https://#{instance}/oauth/token",
      :post,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: "http://localhost:3000/settings/mastodon_callback?instance=#{instance}",
      grant_type: "authorization_code",
      code: code,
      scope: "read"
    ).body
    ps = JSON.parse(res)
    puts "ps:", ps
    tok = ps["access_token"]
    puts "tok:", tok

    if tok.present?
      headers = {"Authorization" => "Bearer #{tok}"}
      res = s.fetch(
        "https://#{instance}/api/v1/accounts/verify_credentials",
        :get,
        nil,
        nil,
        headers
      ).body
      js = JSON.parse(res)
      puts "verify credentials:", js
      if js && js["username"].present?
        return [tok, js["username"]]
      end
    end

    [nil, nil]
  end

  def self.register_application(instance_name)
    s = Sponge.new
    url = "https://#{instance_name}/api/v1/apps"
    res = s.fetch(
      url,
      :post,
      client_name: "lobste.rs",
      redirect_uris: "http://localhost:3000/settings " \
        "http://localhost:3000/settings/mastodon_callback?instance=#{instance_name}",
      scopes: "read",
      website: "https://lobste.rs"
    ).body
    js = JSON.parse(res)
    if js && js["client_id"].present? && js["client_secret"].present?
      MastodonInstance.create!(
        name: instance_name, client_id: js["client_id"], client_secret: js["client_secret"]
      )
      return [js["client_id"], js["client_secret"]]
    end
    [nil, nil]
  end

  def self.sanitized_instance_name(instance_name)
    if instance_name.include? "://"
      URI.parse(instance_name).host
    elsif instance_name.include? "/"
      instance_name.split("/").first
    else
      instance_name
    end
  end

  def self.oauth_auth_url(instance_name)
    instance_name = sanitized_instance_name(instance_name)
    instance = MastodonInstance.find_by(name: instance_name)
    if instance
      client_id = instance.client_id
    else
      client_id, = register_application(instance_name)
    end
    "https://#{instance_name}/oauth/authorize?client_id=#{client_id}&scope=read&redirect_uri=" \
    "http://localhost:3000/settings/mastodon_callback?instance=#{instance_name}&response_type=code"
  end
end
