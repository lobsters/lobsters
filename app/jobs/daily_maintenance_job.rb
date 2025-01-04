class DailyMaintenanceJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ReadRibbon.expire_old_ribbons!
    CommentStat.daily_fill!
  end
end
