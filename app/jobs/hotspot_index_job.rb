class HotspotIndexJob < ApplicationJob
  queue_as :default
  # shares a semaphore with HotspotRefreshJob so doc adds/removes don't double-count
  limits_concurrency to: 1, key: "hotspot", group: "hotspot", duration: 6.hours

  def perform(comment)
    HotspotTerm.refresh! if HotspotDoc.sync!(comment)
  end
end
