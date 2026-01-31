# typed: false

# Comment.above_average needs to compare against the average, which is an expensive dependent
# subquery. CommentStat calculates and stores that once for a fast join.
class CommentStat < ApplicationRecord
  # has_many :comments # date(comments.created_at)

  validates :date, presence: true, uniqueness: true
  validates :average, presence: true

  # Fills daily records for the last 30 days, updating existing rows (in case the job runs don't
  # line up to date boundaries).
  def self.daily_fill!
    Comment.connection.execute <<~SQL
      insert or replace into comment_stats (`date`, `average`)
      with avg_by_date as (
        select
          date(created_at, '-5 hours') as date, avg(score) as a
        from comments
        where
          datetime(comments.created_at, '-5 hours') >= datetime('now', '-30 days') and
          comments.is_deleted = false
        group by date(created_at, '-5 hours')
      )
      select date, a from avg_by_date
    SQL
  end
end
