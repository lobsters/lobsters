# Finds the consistent most-heavily-flagged commenters. Requires flags to be spread over
# several comments and stories because anyone can have a bad thread or a bad day.

class FlaggedCommenters
  include IntervalHelper

  attr_reader :interval, :period, :cache_time

  def initialize(interval, cache_time = 30.minutes)
    @interval = interval
    @cache_time = cache_time
    length = time_interval(interval)
    @period = length[:dur].send(length[:intv].downcase).ago
  end

  def check_list_for(showing_user)
    commenters[showing_user.id]
  end

  # aggregates for all commenters; not just those receiving flags
  def aggregates
    DownvotedCommentersAggregatesQuery.call(self)
  end

  def stddev_sum_flags
    aggregates[:stddev].to_i
  end

  def avg_sum_flags
    aggregates[:avg].to_i
  end

  def commenters
    DownvotedCommentersQuery.call(avg_sum_downvotes, stddev_sum_downvotes, self)
  end
end
