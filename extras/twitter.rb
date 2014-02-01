class Twitter
  cattr_accessor :CONSUMER_KEY, :CONSUMER_SECRET, :AUTH_TOKEN, :AUTH_SECRET

  # these need to be overridden in config/initializers/production.rb
  @@CONSUMER_KEY = nil
  @@CONSUMER_SECRET = nil
  @@AUTH_TOKEN = nil
  @@AUTH_SECRET = nil

  MAX_TWEET_LEN = 140

  # https://t.co/eyW1U2HLtP
  TCO_LEN = 23

  def self.oauth_consumer
    OAuth::Consumer.new(self.CONSUMER_KEY, self.CONSUMER_SECRET,
      { :site => "https://api.twitter.com" })
  end

  def self.oauth_request(req, method = :get, post_data = nil)
    if !self.AUTH_TOKEN
      raise "no auth token configured"
    end

    begin
      Timeout.timeout(120) do
        at = OAuth::AccessToken.new(self.oauth_consumer, self.AUTH_TOKEN,
          self.AUTH_SECRET)

        if method == :get
          res = at.get(req)
        elsif method == :post
          res = at.post(req, post_data)
        else
          raise "what kind of method is #{method}?"
        end

        if res.class == Net::HTTPUnauthorized
          raise "not authorized"
        end

        if res.body.to_s == ""
          raise res.inspect
        else
          return JSON.parse(res.body)
        end
      end
    end
  end
end
