# typed: false

require "silencer/rails/logger"

# In prod, don't prefix the json logs with:
# I, [2024-07-29T21:28:53.921297 #532580]  INFO -- : [53bb48f9-386a-41a0-ad86-b6ef9e780a47]
class EvenSimplerFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, timestamp, progname, msg)
    "#{msg}\n"
  end
end

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.log_formatter = EvenSimplerFormatter.new
  # without this next line, lograge dumps json to journalctl
  config.logger = config.lograge.logger

  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    {
      timestamp: Time.now.utc.iso8601(3),
      params: event.payload[:params].except(*exceptions),
      exception: event.payload[:exception]&.first,
      exception_message: event.payload[:exception]&.last,
      remote_ip: event.payload[:request].remote_ip,
      path: event.payload[:request].original_fullpath || event.payload[:request].fullpath
    }
  end

  config.lograge.custom_payload do |controller|
    {
      user_id: controller.instance_variable_get(:@user)&.id || 0,
      username: controller.instance_variable_get(:@user)&.username || "nobody"
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
