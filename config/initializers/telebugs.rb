module Telebugs
  ENABLED = Rails.application.credentials.telebugs&.dsn.present?
  LOGGER = ActiveSupport::Logger.new(Rails.env.production? ? Rails.root.join("log/exception.log") : $stdout, skip_header: true)

  def self.breadcrumb(**)
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(**))
  end

  def self.capture(exception)
    event = Sentry.capture_exception(exception)
    log(exception.class.name, exception.message, event_id: event&.event_id, backtrace: exception.backtrace&.first(20))
  end

  def self.context(name, value)
    Sentry.configure_scope { |scope| scope.set_context(name, value) }
  end

  def self.message(msg, **options)
    Sentry.capture_message(msg, **options)
  end

  def self.user(id:, username:, email:, ip_address:)
    Sentry.set_user(id:, username:, email:, ip_address:)
  end

  def self.log(exception, message, **fields)
    LOGGER.info({timestamp: Time.now.utc.iso8601(3), exception:, exception_message: message, **fields}.to_json)
  rescue => e
    Rails.logger.error("Telebugs.log failed: #{e.class}: #{e.message}")
  end

  # Sentry sends from a background thread, so capture can't see failures; log them here.
  class LogReportingFailures < Sentry::HTTPTransport
    def send_event(event)
      super
    rescue => e
      Telebugs.log(e.class.name, e.message, event_id: event.event_id)
      raise
    end
  end

  Sentry.init do |config|
    config.dsn = Rails.application.credentials.telebugs&.dsn
    config.transport.transport_class = LogReportingFailures
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.send_default_pii = true # request headers and IP
  end
end

LOBSTERS_GIT_HEAD = ENV["REVISION"] || "unknown" # https://hatchbox.relationkit.io/articles/73-deploy-script-variables
