class RefillStoryPageCacheJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "prefill_page_cache"

  def perform
    Story.unmerged.not_deleted(nil).select(:id, :short_id, :title).find_in_batches(order: :desc) do |batch|
      jobs = batch.map { |story| CachePageJob.new(Routes.title_path(story)).set(queue: :idle) }
      ActiveJob.perform_all_later(jobs)
    end
  end
end
