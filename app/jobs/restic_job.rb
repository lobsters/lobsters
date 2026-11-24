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
    # sasl_passwd is root-only; root-deploy backs it up as part of /etc
    system(<<~SH, exception: true)
      . #{shared}/etc/restic-env ;
      restic backup --no-scan \
        --exclude #{shared}/etc/sasl_passwd \
        #{shared}/etc \
        #{shared}/log \
        #{shared}/database-backups \
        #{home}/.bash_history \
        #{home}/.irb_history \
        #{home}/.sqlite_history \
        #{home}/.local/share/caddy
    SH
  end
end
