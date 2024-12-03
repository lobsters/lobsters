# typed: false

class Pushover
  # see README.md on setting up credentials

  def self.enabled?
    Rails.application.credentials.pushover.api_token.present?
  end

  def self.push(user, params)
    if !enabled?
      return
    end

    begin
      if params[:message].to_s == ""
        params[:message] = "(No message)"
      end

      s = Sponge.new
      s.fetch("https://api.pushover.net/1/messages.json", :post, {
        token: Rails.application.credentials.pushover.api_token,
        user: user
      }.merge(params))
    rescue => e
      Rails.logger.error "error sending to pushover: #{e.inspect}"
    end
  end

  def self.subscription_url(params)
    u = "https://pushover.net/subscribe/#{Rails.application.credentials.pushover.subscription_code}"
    u << "?success=#{CGI.escape(params[:success])}"
    u << "&failure=#{CGI.escape(params[:failure])}"
    u
  end
end
