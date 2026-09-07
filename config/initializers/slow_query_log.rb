if ENV["ENABLE_SLOW_QUERY_LOGS"] == "true"
  threshold = ENV["SLOW_QUERY_THRESHOLD_MS"].present? ? ENV["SLOW_QUERY_THRESHOLD_MS"].to_f : 100
  logger = ActiveSupport::Logger.new(Rails.root.join("log/slow_query.log"))
  logger.formatter = proc do |severity, time, _progname, msg|
    {
      timestamp: time.utc.iso8601(3),
      severity: severity
    }.merge(msg).to_json + "\n"
  end

  ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
    if event.duration > threshold
      logger.warn(duration_ms: event.duration.round(1), sql: event.payload[:sql])
    end
  end
end
