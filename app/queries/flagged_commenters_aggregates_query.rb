class FlaggedCommentersAggregatesQuery
  def self.call(relation)
    new(relation).execute
  end

  def initialize(relation)
    @relation = relation
  end

  def execute
    Rails.cache.fetch("aggregates_#{@relation.interval}_#{@relation.cache_time}",
      expires_in: @relation.cache_time) {
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
            (comments.created_at >= '#{@relation.period}') and
            users.banned_at is null and
            users.deleted_at is null
          GROUP BY comments.user_id
        ) sums;
      ").first.symbolize_keys!
    }
  end
end
