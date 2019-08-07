# This template for a production-only config file of API tokens was taken and
# cleaned up from Lobsters.
#
# Copy this to config/initializers/production.rb and customize, it's already
# listed in .gitignore to help prevent you from accidentally committing it.
#
# This predates Rails' config/secrets.yml feature and we could probably shift
# to using that at some point.

if Rails.env.production?
  Lobsters::Application.config.middleware.use ExceptionNotification::Rack,
    :ignore_exceptions => [
      "ActionController::UnknownFormat",
      "ActionController::BadRequest",
      "ActionDispatch::RemoteIp::IpSpoofAttackError",
    ] + ExceptionNotifier.ignored_exceptions,
    :email => {
      :email_prefix => "[site] ",                    # fill in site name
      :sender_address => %{"Exception Notifier" <>}, # fill in from address
      :exception_recipients => %w{},                 # fill in destination addresses
    }

  Pushover.API_TOKEN = "secret"
  Pushover.SUBSCRIPTION_CODE = "secret"

  StoryCacher.DIFFBOT_API_KEY = "secret"

  Twitter.CONSUMER_KEY = "secret"
  Twitter.CONSUMER_SECRET = "secret"
  Twitter.AUTH_TOKEN = "secret"
  Twitter.AUTH_SECRET = "secret"

  Github.CLIENT_ID = "secret"
  Github.CLIENT_SECRET = "secret"

  BCrypt::Engine.cost = 12

  Keybase.DOMAIN = Rails.application.domain
  Keybase.BASE_URL = ENV.fetch('KEYBASE_BASE_URL') { 'https://keybase.io' }

  ActionMailer::Base.delivery_method = :sendmail

  class << Rails.application
    def allow_invitation_requests?
      false
    end

    def domain
      "example.org"
    end

    def name
      "Sitename"
    end

    def ssl?
      true
    end
  end
end
