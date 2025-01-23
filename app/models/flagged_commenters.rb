# typed: false

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
    Rails.cache.fetch("aggregates_#{interval}_#{cache_time}", expires_in: cache_time) {
      ActiveRecord::Base.connection.exec_query("
        select
          stddev(sum_flags) as stddev,
          sum(sum_flags) as sum,
          avg(sum_flags) as avg,
          avg(n_comments) as n_comments,
          count(*) as n_commenters
        from (
          select
            sum(flags) as sum_flags,
            count(*) as n_comments
          from comments join users on comments.user_id = users.id
          where
            (comments.created_at >= '#{period}') and
            users.banned_at is null and
            users.deleted_at is null
          GROUP BY comments.user_id
        ) sums;
      ").first.symbolize_keys!
    }
  end

  def stddev_sum_flags
    aggregates[:stddev].to_f
  end

  def avg_sum_flags
    aggregates[:avg].to_f
  end

  def commenters
    Rails.cache.fetch("flagged_commenters_#{interval}_#{cache_time}",
      expires_in: cache_time) {
      rank = 0
      User.active.joins(:comments)
        .where("comments.created_at >= ?", period)
        .group("comments.user_id")
        .select("
          users.id, users.username,
          (sum(flags) - #{avg_sum_flags})/#{stddev_sum_flags} as sigma,
          count(distinct if(flags > 0, comments.id, null)) as n_comments,
          count(distinct if(flags > 0, story_id, null)) as n_stories,
          sum(flags) as n_flags,
          sum(flags)/count(distinct comments.id) as average_flags,
          (
            count(distinct if(flags > 0, comments.id, null)) /
            count(distinct comments.id)
          ) * 100 as percent_flagged")
        .having("n_comments > 4 and n_stories > 1 and n_flags >= 10 and percent_flagged > 10")
        .order(sigma: :desc)
        .limit(30)
        .each_with_object({}) { |u, hash|
          hash[u.id] = {
            username: u.username,
            rank: rank += 1,
            sigma: u.sigma,
            n_comments: u.n_comments,
            n_stories: u.n_stories,
            n_flags: u.n_flags,
            average_flags: u.average_flags,
            stddev: 0,
            percent_flagged: u.percent_flagged
          }
        }
    }
  end
end
