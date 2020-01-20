# Finds the consistent most-heavily-downvoted commenters. Requires downvotes to be spread over
# several comments and stories because anyone can have a bad thread or a bad day.

class DownvotedCommenters
  include IntervalHelper

  CACHE_TIME = 30.minutes

  attr_reader :interval, :period

  def initialize(interval)
    @interval = interval
    length = time_interval(interval)
    @period = length[:dur].send(length[:intv].downcase).ago
  end

  def check_list_for(showing_user)
    commenters[showing_user.id]
  end

  # aggregates for all commenters; not just those receiving downvotes
  def aggregates
    Rails.cache.fetch("aggregates_#{interval}", expires_in: CACHE_TIME) {
      ActiveRecord::Base.connection.exec_query("
        select
          stddev(sum_downvotes) as stddev,
          sum(sum_downvotes) as sum,
          avg(sum_downvotes) as avg,
          avg(n_comments) as n_comments,
          count(*) as n_commenters
        from (
          select
            sum(downvotes) as sum_downvotes,
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

  def stddev_sum_downvotes
    aggregates[:stddev].to_i
  end

  def avg_sum_downvotes
    aggregates[:avg].to_i
  end

  def commenters
    Rails.cache.fetch("downvoted_commenters_#{interval}", expires_in: CACHE_TIME) {
      rank = 0
      User.active.joins(:comments)
        .where("comments.created_at >= ?", period)
        .group("comments.user_id")
        .select("
          users.id, users.username,
          (sum(downvotes) - #{avg_sum_downvotes})/#{stddev_sum_downvotes} as sigma,
          count(distinct if(downvotes > 0, comments.id, null)) as n_comments,
          count(distinct if(downvotes > 0, story_id, null)) as n_stories,
          sum(downvotes) as n_downvotes,
          sum(downvotes)/count(distinct comments.id) as average_downvotes,
          (
            count(distinct if(downvotes>0, comments.id, null)) /
            count(distinct comments.id)
          ) * 100 as percent_downvoted")
        .having("n_comments > 4 and n_stories > 1 and n_downvotes >= 10 and percent_downvoted > 10")
        .order("sigma desc")
        .limit(30)
        .each_with_object({}) {|u, hash|
          hash[u.id] = {
            username: u.username,
            rank: rank += 1,
            sigma: u.sigma,
            n_comments: u.n_comments,
            n_stories: u.n_stories,
            n_downvotes: u.n_downvotes,
            average_downvotes: u.average_downvotes,
            stddev: 0,
            percent_downvoted: u.percent_downvoted,
          }
        }
    }
  end
end
