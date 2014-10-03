class TrafficCounterWorker
  include Sidekiq::Worker

  def perform(traffic_decrementer)
    Keystore.transaction do
      now_i = Time.now.to_i
      date_kv = Keystore.find_or_create_key_for_update("traffic:date", now_i)
      traffic_kv = Keystore.find_or_create_key_for_update("traffic:hits", 0)

      # increment traffic counter on each request
      traffic = traffic_kv.value.to_i + 100
      # every second, decrement traffic by some amount
      traffic -= (100.0 * (now_i - date_kv.value) * traffic_decrementer).to_i
      # clamp
      traffic = [ 100, traffic ].max

      traffic = traffic * 0.01

      traffic_kv.value = traffic
      traffic_kv.save!

      date_kv.value = now_i
      date_kv.save!

      Rails.logger.info "  Traffic level: #{traffic}"
    end
  end
end
