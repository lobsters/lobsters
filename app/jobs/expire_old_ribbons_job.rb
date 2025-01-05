class ExpireOldRibbonsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ReadRibbon.expire_old_ribbons!
  end
end
