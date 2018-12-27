# define site name and domain to be used globally, should be overridden in a
# local file such as config/site.yml
SITE_CONFIG = Rails.application.config_for(:site)

class << Rails.application
  def allow_invitation_requests?
    SITE_CONFIG['allow_invitation_requests']
  end

  def open_signups?
    SITE_CONFIG['open_signups']
  end

  def domain
    SITE_CONFIG['domain']
  end

  def name
    SITE_CONFIG['name']
  end

  # to force everyone to be considered logged-out (without destroying
  # sessions) and refuse new logins
  def read_only?
    SITE_CONFIG['read_only']
  end

  def root_url
    Rails.application.routes.url_helpers.root_url(
      :host => Rails.application.domain,
      :protocol => Rails.application.ssl? ? "https" : "http",
    )
  end

  # used as mailing list prefix, cannot have spaces
  def shortname
    name.downcase.gsub(/[^a-z]/, "")
  end

  # whether absolute URLs should include https (does not require that
  # config.force_ssl be on)
  def ssl?
    true
  end

  def use_elasticsearch?
    SITE_CONFIG['elasticsearch']['enabled']
  end
end

# Api tokens used for various services we consume
Pushover.API_TOKEN = Rails.application.secrets.pushover[:api_token]
Pushover.SUBSCRIPTION_CODE = Rails.application.secrets.pushover[:subscription_code]

StoryCacher.DIFFBOT_API_KEY = Rails.application.secrets.story_cacher[:diffbot_api_key]

Twitter.CONSUMER_KEY = Rails.application.secrets.twitter[:consumer_key]
Twitter.CONSUMER_SECRET = Rails.application.secrets.twitter[:consumer_secret]
Twitter.AUTH_TOKEN = Rails.application.secrets.twitter[:auth_token]
Twitter.AUTH_SECRET = Rails.application.secrets.twitter[:auth_secret]

Github.CLIENT_ID = Rails.application.secrets.github[:client_id]
Github.CLIENT_SECRET = Rails.application.secrets.github[:client_id]

# Email exception notifications
%w{render_template render_partial render_collection}.each do |event|
  ActiveSupport::Notifications.unsubscribe "#{event}.action_view"
end

if Rails.env.production?
  Lobsters::Application.config.middleware.use ExceptionNotification::Rack,
                                              :ignore_exceptions => [
                                                "ActionController::UnknownFormat",
                                                "ActionController::BadRequest",
                                                "ActionDispatch::RemoteIp::IpSpoofAttackError",
                                              ] + ExceptionNotifier.ignored_exceptions,
                                              :email => {
                                                :email_prefix =>
                                                "[#{Rails.application.name}] ",
                                                :sender_address =>
                                                SITE_CONFIG['exception_notifications']['reply_to'],
                                                :exception_recipients =>
                                                SITE_CONFIG['exception_notifications']['emails'],
                                              }
end
