class CachePageJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(path) { path }, on_conflict: :discard

  def perform(path)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! Rails.application.config.action_mailer.default_url_options[:host]
    session.https! # force_ssl would 301

    session.get(path)
    raise "CachePageJob: #{session.response.status} from #{path}" if session.response.status >= 500
    return unless session.response.status == 200 # don't cache error pages, nothing would expire them

    ApplicationController.cache_page(session.response.body, path, nil, false)

    # after writing, remove any caches with old title slugs
    if path.start_with?("/s/")
      file = File.join(ActionController::Base.page_cache_directory, "#{path}.html")
      story_dir = File.dirname(file)
      FileUtils.rm_f(Dir.glob(File.join(story_dir, "*.html")) - [file])
      # and also /s/:short_id.:format because of the rails misdesign explained in #746
      FileUtils.rm_f(Dir.glob("#{story_dir}.*"))
    end
  end
end
