class CachePageJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(path) { path }, on_conflict: :discard

  def perform(path)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! Rails.application.config.action_mailer.default_url_options[:host]
    session.https! # force_ssl would 301

    session.get(path)
    raise "CachePageJob: #{session.response.status} from #{path}" unless session.response.status == 200

    ApplicationController.cache_page(session.response.body, path, nil, false)

    # after writing, remove any caches with old title slugs
    if path.start_with?("/s/")
      file = File.join(ActionController::Base.page_cache_directory, "#{path}.html")
      FileUtils.rm_f(Dir.glob(File.join(File.dirname(file), "*.html")) - [file])
    end
  end
end
