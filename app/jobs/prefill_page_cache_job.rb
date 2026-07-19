# Prefill the full-page cache with the most-popular pages rather than get dogpiled and rerender them
# multiple times when cleared by expire_page_cache.
class PrefillPageCacheJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "prefill_page_cache"

  def perform
    paths.each { |path| prerender path }
  end

  def paths
    hottest, _ = StoriesPaginator.new(Story.hottest(nil, []), 1, nil).get
    active, _ = StoriesPaginator.new(Story.active(nil, []), 1, nil).get

    %w[/ /active /recent /comments /newest /users] +
      (hottest + active).uniq.map { |s| Routes.title_path s }
  end

  def prerender(path)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! Rails.application.config.action_mailer.default_url_options[:host]
    session.https! # force_ssl would 301

    session.get(path)
    raise "PrefillPageCacheJob: #{session.response.status} from #{path}" unless session.response.status == 200

    ApplicationController.cache_page(session.response.body, path, nil, false)
  end
end
