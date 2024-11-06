# typed: false

desc "Daily maintenance tasks"
task daily_maintenance: :environment do
  ReadRibbon.expire_old_ribbons!
  CommentStat.daily_fill!
end
