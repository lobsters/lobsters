# typed: false

require "active_support/parameter_filter"
require "silencer/rails/logger"

Rails.application.configure do
  # https://hatchbox.relationkit.io/articles/61-accessing-your-server-logs-in-hatchbox
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    stdout_logger = ActiveSupport::Logger.new($stdout)
    stdout_logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(stdout_logger)
  end

  lograge_logger = ActiveSupport::Logger.new(Rails.env.production? ? "/tmp/production.log" : $stdout)
  config.lograge.formatter = Lograge::Formatters::Json.new
  broadcast = ActiveSupport::BroadcastLogger.new(stdout_logger, lograge_logger)
  config.logger = broadcast

  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.lograge.custom_options = lambda do |event|
    {
      timestamp: Time.now.utc.iso8601(3),
      params: filter.filter(event.payload[:request].query_parameters.merge(event.payload[:request].request_parameters)),
      exception: event.payload[:exception]&.first,
      exception_message: event.payload[:exception]&.last,
      remote_ip: event.payload[:request].remote_ip
    }.tap do |options|
      event.payload.except!(:allocations, :duration, :view_runtime, :db_runtime)
    end
  end

  config.lograge.custom_payload do |controller|
    {
      user_id: controller.instance_variable_get(:@user)&.id || 0,
      username: controller.instance_variable_get(:@user)&.username || "nobody",
      path: controller.instance_variable_get(:@requested_path) || controller.request.original_fullpath
    }
  end

  if Rails.env.development?
    config.lograge.keep_original_rails_log = true
    config.lograge.logger = ActiveSupport::Logger.new($stdout)
  end
end

# Silence asset logging in development
if Rails.env.development?
  Rails.application.configure do
    config.assets.logger = ActiveSupport::Logger.new(nil)
    config.middleware.insert_before Rails::Rack::Logger, Silencer::Logger, silence: [%r{^/assets/}]
  end
end
