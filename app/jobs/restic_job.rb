class ResticJob < ApplicationJob
  queue_as :default

  def perform(*args)
    shared = "/home/deploy/lobsters/shared"
    system("source #{shared}/etc/restic-env ; restic backup --no-scan #{shared}/etc #{shared}/log")
  end
end
