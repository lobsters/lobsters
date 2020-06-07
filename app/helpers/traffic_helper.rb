# activity: is the weighted sum of votes, comments, and stories in some time period
# period: 15 minute block of time
# range: high and low of periods in the last few months
# intensity: what % of the range the current activity is (0-100)
module TrafficHelper
  PERIOD_LENGTH = 15 # minutes
  CACHE_FOR = 5 # minutes

  def self.traffic_range
    div = PERIOD_LENGTH * 60
    start_at = 90.days.ago
    result = ActiveRecord::Base.connection.execute <<-SQL
      select
        min(activity) as low,
        max(activity) as high
      from
        (select
          -- from_unixtime(s.period * #{div}) as "at",
          -- s.period,
          v.n_votes + (c.n_comments * 10) + (s.n_stories * 20) AS activity
        from
          (SELECT count(1) AS n_votes,    floor(UNIX_TIMESTAMP(updated_at)/#{div}) AS period FROM votes    WHERE updated_at >= "#{start_at}" GROUP BY period) v,
          (SELECT count(1) AS n_comments, floor(UNIX_TIMESTAMP(created_at)/#{div}) AS period FROM comments WHERE created_at >= "#{start_at}" GROUP BY period) c,
          (SELECT count(1) AS n_stories,  floor(UNIX_TIMESTAMP(created_at)/#{div}) AS period FROM stories  WHERE created_at >= "#{start_at}" GROUP BY period) s
        where
          s.period = c.period and
          s.period = v.period) act;
    SQL
    result.to_a.first
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
    start_at = 15.minutes.ago
    result = ActiveRecord::Base.connection.execute <<-SQL
      select
        (SELECT count(1) AS n_votes   FROM votes    WHERE updated_at >= "#{start_at}") +
        (SELECT count(1) AS n_comment FROM comments WHERE created_at >= "#{start_at}") * 10 +
        (SELECT count(1) AS n_stories FROM stories  WHERE created_at >= "#{start_at}") * 20
    SQL
    result.to_a.first.first
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
