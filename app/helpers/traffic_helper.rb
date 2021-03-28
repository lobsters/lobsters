# activity: is the weighted sum of votes, comments, and stories in some time period
# period: 15 minute block of time
# range: high and low of periods in the last few months
# intensity: what % of the range the current activity is (0-100)
module TrafficHelper
  PERIOD_LENGTH = 15 # minutes
  CACHE_FOR = 5 # minutes

  def self.traffic_range
    return [0, 2]
  end

  def self.cached_traffic_range
    low, high = nil, nil
    low = Keystore.readthrough_cache('traffic:low') do
      low, high = traffic_range
      Keystore.put('traffic:high', high)
      low
    end
    high ||= Keystore.value_for('traffic:high')
    [low, high]
  end

  def self.current_activity
    return 1
  end

  def self.current_intensity
    low, high = cached_traffic_range
    return 0.5 if low.nil? || high.nil? || high == low
    activity = [low, current_activity, high].sort[1]
    [0, ((activity - low)*1.0/(high - low) * 100).round, 100].sort[1]
  end

  def self.current_period_key
    "traffic:at:#{(Time.now.utc.to_i/CACHE_FOR.minutes).floor}"
  end

  def self.cached_current_intensity
    Keystore.readthrough_cache(current_period_key) do
      current_intensity
    end
  end
end
