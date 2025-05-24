class Telebugs
  def self.breadcrumb *args, **kwargs
  end

  def self.context *args, **kwargs
  end

  def self.user *args, **kwargs
  end
end

if Rails.application.credentials.telebugs.present?
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.telebugs.dsn

    # get breadcrumbs from logs
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Add data like request headers and IP for users, if applicable;
    # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
    config.send_default_pii = true
  end

  class Telebugs
    # https://docs.sentry.io/platforms/ruby/guides/rails/enriching-events/breadcrumbs/
    def breadcrumb *args
      Sentry.add_breadcrumb(Sentry::Breadcrumb.new(*args))
    end

    # https://docs.sentry.io/platforms/ruby/guides/rails/enriching-events/context/
    def context name, value
      Sentry.configure_scope do |scope|
        scope.set_context(name, value)
      end
    end

    def user id:, username:, email:, ip_address:
      Sentry.set_user id:, username:, email:, ip_address:
    end
  end
end

LOBSTERS_GIT_HEAD = ENV["REVISION"] || "unknown" # https://hatchbox.relationkit.io/articles/73-deploy-script-variables
