# Prefill the full-page cache with the most-popular pages rather than get dogpiled and rerender them
# multiple times when cleared by expire_page_cache.
class PrefillPageCacheJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "prefill_page_cache"

  def perform
    jobs = paths.map { |path| CachePageJob.new(path).set(queue: :default) }
    ActiveJob.perform_all_later(jobs)
  end

  def paths
    hottest, _ = StoriesPaginator.new(Story.hottest(nil, []), 1, nil).get
    active, _ = StoriesPaginator.new(Story.active(nil, []), 1, nil).get

    %w[/ /active /recent /comments /newest /users] +
      (hottest + active).uniq.map { |s| Routes.title_path s }
  end
end
