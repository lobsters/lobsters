# typed: false

class Mastodon
  # see README.md on setting up credentials

  def self.enabled?
    Rails.application.credentials.mastodon&.token.present?
  end

  MAX_STATUS_LENGTH = 500 # https://docs.joinmastodon.org/user/posting/#text
  LINK_LENGTH = 23 # https://docs.joinmastodon.org/user/posting/#links

  def self.accept_follow_request(id)
    s = Sponge.new
    response = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/follow_requests/#{id}/authorize",
      :post,
      {limit: 80},
      nil,
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
    raise "failed to accept follow request #{id}" if response.nil?
  end

  def self.add_list_accounts(accts)
    s = Sponge.new
    response = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/lists/#{Rails.application.credentials.mastodon.list_id}/accounts",
      :post,
      nil,
      accts.map { |i| "account_ids[]=#{i}" }.join("&"),
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
    raise "failed to add to list" if response.nil? || puts(response.body) || JSON.parse(response.body) != {}
  end

  def self.delete_post(story)
    return nil if story.mastodon_id.nil? || story.mastodon_id == "0"

    s = Sponge.new
    s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/statuses/#{story.mastodon_id}",
      :delete,
      {},
      nil,
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
  end

  def self.follow_account(id)
    s = Sponge.new
    response = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/accounts/#{id}/follow",
      :post,
      {reblogs: false},
      nil,
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
    raise "failed to follow #{id}" if response.nil?
  end

  def self.get_account_id(acct)
    s = Sponge.new
    response = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/accounts/search",
      :get,
      nil,
      {q: acct, limit: 80, resolve: true},
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
    raise "failed to lookup #{acct}" if response.nil?
    accounts = JSON.parse(response.body)

    account = accounts.find { |a| a["acct"] == acct }
    # treehouse.systems is hosted at social.treehouse.systems
    # no idea why that's inconsistent or a better way to reconcile
    account = accounts.find { |a| acct.split("@").first } if account.nil?
    raise "did not find acct #{acct} in #{accounts}" if account.nil?
    account["id"]
  end

  # returns list of ids for accept_follow_request calls
  def self.get_follow_requests
    s = Sponge.new
    response = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/follow_requests",
      :get,
      nil,
      nil,
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
    accounts = JSON.parse(response.body)
    accounts.pluck("id")
  end

  # returns { "user@example.com" => 123 } for remove_list_accounts call
  def self.get_list_accounts
    s = Sponge.new
    response = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/lists/#{Rails.application.credentials.mastodon.list_id}/accounts",
      :get,
      {limit: 0},
      nil,
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
    accounts = JSON.parse(response.body)
    accounts.map { |a| [a["acct"], a["id"]] }.to_h
  end

  def self.post(status)
    s = Sponge.new
    s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/statuses",
      :post,
      {
        status: status,
        visibility: "public"
      },
      nil,
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
  end

  def self.remove_list_accounts(ids)
    s = Sponge.new
    response = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/lists/#{Rails.application.credentials.mastodon.list_id}/accounts",
      :delete,
      {account_ids: ids},
      nil,
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
    raise "failed to remove from list" if response.nil? || JSON.parse(response.body) != {}
  end

  def self.unfollow_account(id)
    s = Sponge.new
    response = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/accounts/#{id}/unfollow",
      :post,
      {account_ids: ids},
      nil,
      {"Authorization" => "Bearer #{Rails.application.credentials.mastodon.token}"}
    )
    raise "failed to remove from list" if response.nil? || JSON.parse(response.body) != {}
  end

  def self.get_bot_credentials!
    raise "instructions in README.md" unless Rails.application.credentials.mastodon.instance_name && Rails.application.credentials.mastodon.bot_name

    if !Rails.application.credentials.mastodon.client_id ||
        !Rails.application.credentials.mastodon.client_secret
      s = Sponge.new
      url = "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/apps"
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
        errors.add :base, "App registration failed, is #{Rails.application.credentials.mastodon.instance_name} a Mastodon instance?"
        return
      end
      reg = JSON.parse(res.body)
      raise "no json" if !reg
      raise "no client_id" if reg["client_id"].blank?
      raise "no client_secret" if reg["client_secret"].blank?
    end

    client_id = Rails.application.credentials.client_id || reg["client_id"]
    client_secret = Rails.application.credentials.client_secret || reg["client_secret"]

    puts
    puts "open this URL and authorize read/write access for the bot account"
    puts "you'll get redirected to your site's /settings?code=..."
    puts "https://#{Rails.application.credentials.mastodon.instance_name}/oauth/authorize?response_type=code&client_id=#{client_id}&scope=read+write&redirect_uri=" +
      CGI.escape(
        "https://#{Rails.application.domain}/settings"
      )
    puts

    puts "what is the value after code= (not the whole URL, just what's after the =)"
    code = gets.chomp

    s = Sponge.new
    res = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/oauth/token",
      :post,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: "https://#{Rails.application.domain}/settings",
      grant_type: "authorization_code",
      code: code,
      scope: "read write"
    )
    raise "mastodon getting user token failed, response from #{Rails.application.credentials.mastodon.instance_name} was nil" if res.nil?
    ps = JSON.parse(res.body)
    tok = ps["access_token"]
    raise "no token" if tok.blank?

    headers = {"Authorization" => "Bearer #{tok}"}
    res = s.fetch(
      "https://#{Rails.application.credentials.mastodon.instance_name}/api/v1/accounts/verify_credentials",
      :get,
      nil,
      nil,
      headers
    ).body
    js = JSON.parse(res)
    if Rails.application.credentials.mastodon.bot_name != js["username"]
      puts "uhh Rails.application.credentials.mastodon.bot_name='#{Rails.application.credentials.mastodon.bot_name}' but the instance thinks it's '#{js["username"]}' and the instance wins that disagreement"
    end

    puts

    puts "add these values in into the 'mastodon:' section of 'rails credentials:edit'"
    puts "  client_id: \"#{client_id}\""
    puts "  client_secret: \"#{client_secret}\""
    puts "  token: \"#{tok}\""
    true
  end
end
