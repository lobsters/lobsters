class ResticJob < ApplicationJob
  queue_as :default

  def perform(*args)
    home = "/home/deploy"
    shared = "#{home}/lobsters/shared"
    unless File.directory?(shared)
      raise "ResticJob: shared path '#{shared}' does not exist, can't back up"
    end
    db_path = Rails.root.join("storage/primary.sqlite3")
    system(Rails.root.join("bin/sqlite3").to_s, db_path.to_s,
      ".backup '#{shared}/database-backups/primary.sqlite3'", exception: true)
    # must use . instead of source because prod is using sh instead of bash
    system(". #{shared}/etc/restic-env ; restic backup --no-scan #{shared}/etc #{shared}/log #{shared}/database-backups #{home}/.*_history", exception: true)
  end
end
