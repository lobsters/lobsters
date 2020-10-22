class FlaggedCommentersQuery
  def self.call(avg_sum_downvotes, stddev_sum_downvotes, relation)
    new(avg_sum_downvotes, stddev_sum_downvotes, relation).execute
  end

  def initialize(avg_sum_flags, stddev_sum_flags, relation)
    @avg_sum_flags = avg_sum_flags
    @stddev_sum_flags = stddev_sum_flags
    @relation = relation
  end

  def execute
    Rails.cache.fetch("flagged_commenters_#{self.interval}_#{self.cache_time}",
                      expires_in: self.cache_time) {
      rank = 0
      User.active.joins(:comments)
        .where("comments.created_at >= ?", self.period)
        .group("comments.user_id")
        .select("
          users.id, users.username,
          (sum(flags) - #{@avg_sum_flags})/#{@stddev_sum_flags} as sigma,
          count(distinct if(flags > 0, comments.id, null)) as n_comments,
          count(distinct if(flags > 0, story_id, null)) as n_stories,
          sum(flags) as n_flags,
          sum(flags)/count(distinct comments.id) as average_flags,
          (
            count(distinct if(flags > 0, comments.id, null)) /
            count(distinct comments.id)
          ) * 100 as percent_flagged")
          .having("n_comments > 4 and n_stories > 1 and n_flags >= 10 and percent_flagged > 10")
          .order("sigma desc")
          .limit(30)
          .each_with_object({}) {|u, hash|
          hash[u.id] = {
            username: u.username,
            rank: rank += 1,
            sigma: u.sigma,
            n_comments: u.n_comments,
            n_stories: u.n_stories,
            n_flags: u.n_flags,
            average_flags: u.average_flags,
            stddev: 0,
            percent_flagged: u.percent_flagged,
          }
      }
    }
  end
end
