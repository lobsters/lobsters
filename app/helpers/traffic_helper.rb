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
          (SELECT count(1) AS n_votes,    floor(UNIX_TIMESTAMP(updated_at)/#{div}) AS period FROM votes    WHERE updated_at >= '#{start_at}' GROUP BY period) v,
          (SELECT count(1) AS n_comments, floor(UNIX_TIMESTAMP(created_at)/#{div}) AS period FROM comments WHERE created_at >= '#{start_at}' GROUP BY period) c,
          (SELECT count(1) AS n_stories,  floor(UNIX_TIMESTAMP(created_at)/#{div}) AS period FROM stories  WHERE created_at >= '#{start_at}' GROUP BY period) s
        where
          s.period = c.period and
          s.period = v.period) act;
    SQL
    result.to_a.first
  end

  def self.cache_traffic!
    low, high = self.traffic_range
    Keystore.put('traffic:low', low)
    Keystore.put('traffic:high', high)
    Keystore.put('traffic:intensity', current_intensity(low, high))
  end

  def self.current_activity
    start_at = PERIOD_LENGTH.minutes.ago.utc
    result = ActiveRecord::Base.connection.execute <<-SQL
      select
        (SELECT count(1) AS n_votes   FROM votes    WHERE updated_at >= '#{start_at}') +
        (SELECT count(1) AS n_comment FROM comments WHERE created_at >= '#{start_at}') * 10 +
        (SELECT count(1) AS n_stories FROM stories  WHERE created_at >= '#{start_at}') * 20
    SQL
    result.to_a.first.first
  end

  def self.current_intensity(low, high)
    return 0.5 if low.nil? || high.nil? || high == low
    activity = [low, current_activity, high].sort[1]
    [0, ((activity - low)*1.0/(high - low) * 100).round, 100].sort[1]
  end

  def self.cached_current_intensity
    Keystore.value_for('traffic:intensity') || 0.5
  end

  # rubocop:disable Layout/LineLength
  def self.novelty_logo
    time = Time.current

    if time.month == 6 && time.day == 28 # Stonewall riots
      return "background: linear-gradient(180deg, #FE0000 16.66%, #FD8C00 16.66%, 33.32%, #FFE500 33.32%, 49.98%, #119F0B 49.98%, 66.64%, #0644B3 66.64%, 83.3%, #C22EDC 83.3%);"
    elsif time.month == 12 && time.day == 25 # Christmas
      return "background: conic-gradient(at 50% 0, #9f3631 157.5deg, #01c94f 0, #01c94f 202.5deg, #9f3631 0);"
    end

    nil
  end
  # rubocop:enable Layout/LineLength
end
