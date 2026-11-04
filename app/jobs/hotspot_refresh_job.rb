class HotspotRefreshJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "hotspot", group: "hotspot", duration: 6.hours, on_conflict: :discard

  def perform(from_scratch: false)
    HotspotDoc.rebuild! if from_scratch
    HotspotDoc.expire!
    HotspotTerm.refresh!
  end
end
