class FillFlaggedCacheJob < ApplicationJob
  queue_as :default

  # fills the cache - used by app/views/users/show.html.erb for mods
  def perform(*args)
    FlaggedCommenters.new("1m").commenters
  end
end
