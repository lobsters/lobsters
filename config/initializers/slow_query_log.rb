if ENV["ENABLE_SLOW_QUERY_LOGS"] == "true"
  threshold = ENV["SLOW_QUERY_THRESHOLD_MS"].present? ? ENV["SLOW_QUERY_THRESHOLD_MS"].to_f : 100

  ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
    if event.duration > threshold
      Rails.logger.warn("[SLOW QUERY] #{event.duration.round(1)} ms, #{event.payload[:sql]}")
    end
  end
end
