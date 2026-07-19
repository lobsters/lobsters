class ResticJob < ApplicationJob
  queue_as :default

  def perform(*args)
    shared = "/home/deploy/lobsters/shared"
    unless File.directory?(shared)
      raise "ResticJob: shared path '#{shared}' does not exist, can't back up"
    end
    db_path = Rails.root.join("storage/primary.sqlite3")
    system("sqlite3 #{db_path} \".backup '#{shared}/database-backups/primary.sqlite3'\"", exception: true)
    # must use . instead of source because prod is using sh instead of bash
    system(". #{shared}/etc/restic-env ; restic backup --no-scan #{shared}/etc #{shared}/log #{shared}/database-backups", exception: true)
  end
end
