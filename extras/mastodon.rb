# typed: false

class Mastodon
  def self.enabled?
    true # Rails.env.production?
  end

  # these need to be overridden in config/initializers/production.rb
  cattr_accessor :INSTANCE_NAME, :BOT_NAME, :CLIENT_ID, :CLIENT_SECRET, :TOKEN

  @@INSTANCE_NAME = nil
  @@BOT_NAME = nil
  @@CLIENT_ID = nil
  @@CLIENT_SECRET = nil
  @@TOKEN = nil

  def self.get_bot_credentials!
    raise "instructions in production.rb.sample" unless self.INSTANCE_NAME && self.BOT_NAME

    if !self.CLIENT_ID || !self.CLIENT_SECRET
      s = Sponge.new
      url = "https://#{self.INSTANCE_NAME}/api/v1/apps"
      res = s.fetch(
        url,
        :post,
        client_name: Rails.application.domain,
        redirect_uris: [
          "https://#{Rails.application.domain}/settings"
        ].join("\n"),
        scopes: "read write",
        website: "https://#{Rails.application.domain}"
      )
      if res.nil? || res.body.blank?
        errors.add :base, "App registration failed, is #{self.INSTANCE_NAME} a Mastodon instance?"
        return
      end
      reg = JSON.parse(res.body)
      raise "no json" if !reg
      raise "no client_id" if reg["client_id"].blank?
      raise "no client_secret" if reg["client_secret"].blank?

      puts "Mastodon.CLIENT_ID = \"#{reg["client_id"]}\""
      puts "Mastodon.CLIENT_SECRET = \"#{reg["client_secret"]}\""
    end

    client_id = self.CLIENT_ID || reg["client_id"]
    client_secret = self.CLIENT_SECRET || reg["client_secret"]

    puts
    puts "open this URL and authorize read/write access for the bot account"
    puts "you'll get redirected to /settings?code=..."
    puts "https://#{self.INSTANCE_NAME}/oauth/authorize?response_type=code&client_id=#{client_id}&scope=read+write&redirect_uri=" +
      CGI.escape(
        "https://#{Rails.application.domain}/settings"
      )
    puts

    puts "what is the value after code= (not the whole URL, just what's after the =)"
    code = gets.chomp

    s = Sponge.new
    res = s.fetch(
      "https://#{self.INSTANCE_NAME}/oauth/token",
      :post,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: CGI.escape("https://#{Rails.application.domain}/settings"),
      grant_type: "authorization_code",
      code: code,
      scope: "read write"
    )
    raise "mastodon getting user token failed, response from #{self.INSTANCE_NAME} was nil" if res.nil?
    ps = JSON.parse(res.body)
    tok = ps["access_token"]
    raise "no token" if tok.blank?

    headers = {"Authorization" => "Bearer #{tok}"}
    res = s.fetch(
      "https://#{self.INSTANCE_NAME}/api/v1/accounts/verify_credentials",
      :get,
      nil,
      nil,
      headers
    ).body
    js = JSON.parse(res)
    puts "uhh Mastodon.BOT_NAME='#{Mastodon.BOT_NAME}' but the instance thinks it's '#{js["username"]}' and the instance wins that disagreement" if Mastodon.BOT_NAME != js["username"]

    puts
    puts "Mastodon.TOKEN = \"#{tok}\""
    puts
    puts "copy the three values above to your config/initializers/production.rb"
    true
  end
end
