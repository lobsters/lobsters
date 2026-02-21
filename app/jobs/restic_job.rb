class ResticJob < ApplicationJob
  queue_as :default

  def perform(*args)
    shared = "/home/deploy/lobsters/shared"
    # Check if the shared directory exists
    unless File.directory?(shared)
      Rails.logger.warn "ResticJob: Shared path '#{shared}' does not exist. Skipping backup."
      return
    end
    system("source #{shared}/etc/restic-env ; restic backup --no-scan #{shared}/etc #{shared}/log")
  end
end
