if ENV["ENABLE_SLOW_QUERY_LOGS"] == "true"
  threshold = ENV["SLOW_QUERY_THRESHOLD_MS"].present? ? ENV["SLOW_QUERY_THRESHOLD_MS"].to_f : 100
  logger = ActiveSupport::Logger.new(Rails.root.join("log/slow_query.log"))
  logger.formatter = Logger::Formatter.new

  ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
    if event.duration > threshold
      logger.warn("[SLOW QUERY] #{event.duration.round(1)} ms, #{event.payload[:sql]}")
    end
  end
end
