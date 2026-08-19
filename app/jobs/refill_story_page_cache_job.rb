class RefillStoryPageCacheJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "refill_story_page_cache"

  def perform
    # dedupe + proritize by throwing out anything pages pending from a recent deploy
    SolidQueue::Queue.find_by_name("refill_story_pages").clear
    # delete the concurrency key that would prevent re-engueueing on fast re-deploys
    SolidQueue::Semaphore.where("key LIKE 'CachePageJob/%'").delete_all

    Story.unmerged.not_deleted(nil).select(:id, :short_id, :title).find_in_batches(batch_size: 100, order: :desc) do |batch|
      jobs = batch.map { |story| CachePageJob.new(Routes.title_path(story)).set(queue: :refill_story_pages) }
      ActiveJob.perform_all_later(jobs)
    end
  end
end
