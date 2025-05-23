if Rails.application.credentials.telebugs.present?
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.telebugs.dsn

    # get breadcrumbs from logs
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Add data like request headers and IP for users, if applicable;
    # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
    config.send_default_pii = true
  end
end
