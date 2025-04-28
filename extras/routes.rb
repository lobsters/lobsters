# https://www.youtube.com/watch?v=c14M6QeFVgY
class Routes
  class << self
    # this brings in all of config/routes, eg. root_path or story_short_id_url
    include Rails.application.routes.url_helpers

    def default_url_options
      Rails.application.config.action_mailer.default_url_options
    end

    def story_title_path story
      story_short_id_path(story, title: story.title_as_url)
    end

    def story_title_url story
      story_short_id_url(story, title: story.title_as_url)
    end

    def story_url_or_comments_path story
      story.url.presence || story_title_path(story)
    end

    def story_url_or_comments_url story
      story.url.presence || story_title_url(story)
    end
  end
end

# todo: audit for'url_for
# routes
# other hacky model methods
# x story.url_or_comments_url, url_or_comments_path
# x story.comments_url
#   story.comments_path
#   story.short_id_url, short_id_path
#   comment.short_id_url, short_id_path
#   comment.url
#   rename Routes.story_title_url/_path to just title_url? seems redundant
