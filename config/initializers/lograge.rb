# typed: false

require "active_support/parameter_filter"
require "silencer/rails/logger"

Rails.application.configure do
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.logger = ActiveSupport::Logger.new(Rails.env.production? ? Rails.root.join("log/action.log") : $stdout, skip_header: true)

  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.lograge.custom_options = lambda do |event|
    {
      timestamp: Time.now.utc.iso8601(3),
      # Rack loses the raw client headers to an old API based on Common Gateway Interface so this
      # kludgily recreates a degraded version for the log :(
      headers: event.payload[:request].headers.env.select { (it.start_with? "HTTP_") && (it != "HTTP_COOKIE") }.map { |k, v| [k[5..].downcase.dasherize, v] }.to_h,
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
