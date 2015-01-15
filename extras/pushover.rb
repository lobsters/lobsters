class Pushover
  # these need to be overridden in config/initializers/production.rb
  cattr_accessor :API_TOKEN
  cattr_accessor :SUBSCRIPTION_CODE

  def self.push(user, params)
    if !@@API_TOKEN
      return
    end

    begin
      if params[:message].to_s == ""
        params[:message] = "(No message)"
      end

      s = Sponge.new
      s.fetch("https://api.pushover.net/1/messages.json", :post, {
        :token => @@API_TOKEN,
        :user => user,
      }.merge(params))
    rescue => e
      Rails.logger.error "error sending to pushover: #{e.inspect}"
    end
  end

  def self.subscription_url(params)
    u = "https://pushover.net/subscribe/#{@@SUBSCRIPTION_CODE}"
    u << "?success=#{CGI.escape(params[:success])}"
    u << "&failure=#{CGI.escape(params[:failure])}"
    u
  end
end
