desc 'Daily maintenance tasks'
task dail_maintenance: :environment do
  ReadRibbon.expire_old_ribbons!
end
