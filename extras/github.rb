# typed: false

require "cgi"

class Github
  # see README.md on setting up credentials

  def self.enabled?
    Rails.application.credentials.github&.client_id.present?
  end

  def self.oauth_consumer
    OAuth::Consumer.new(
      Rails.application.credentials.github.client_id,
      Rails.application.credentials.github.client_secret,
      site: "https://api.github.com"
    )
  end

  def self.token_and_user_from_code(code)
    s = Sponge.new
    res = s.fetch(
      "https://github.com/login/oauth/access_token",
      :post,
      client_id: Rails.application.credentials.github.client_id,
      client_secret: Rails.application.credentials.github.client_secret,
      code: code
    ).body
    ps = CGI.parse(res)
    tok = ps["access_token"].first

    if tok.present?
      headers = {"Authorization" => "token #{tok}"}
      res = s.fetch("https://api.github.com/user", :get, nil, nil, headers).body
      js = JSON.parse(res)
      if js && js["login"].present?
        return [tok, js["login"]]
      end
    end

    [nil, nil]
  end

  def self.oauth_auth_url(state)
    "https://github.com/login/oauth/authorize?client_id=#{Rails.application.credentials.github.client_id}&" \
      "state=#{state}"
  end

  def self.revoke_token(token)
    return if token.blank?

    s = Sponge.new
    headers = {
      "Accept" => "application/vnd.github+json",
      "Content-Type" => "application/json",
      "X-GitHub-Api-Version" => "2022-11-28"
    }
    uri = URI::HTTPS.build(
      userinfo: [
        Rails.application.credentials.github.client_id,
        Rails.application.credentials.github.client_secret
      ].join(":"),
      host: "api.github.com",
      path: "/applications/#{Rails.application.credentials.github.client_id}/grant"
    )
    res = s.fetch(uri, :delete, {}, JSON.generate({access_token: token}), headers)
    res.is_a? Net::HTTPSuccess
  end
end
