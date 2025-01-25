class PopulateCommentStatsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    CommentStat.daily_fill!
  end
end
