# https://www.youtube.com/watch?v=c14M6QeFVgY
class Routes
  class << self
    # this brings in all of config/routes, eg. root_path or story_short_id_url
    include Rails.application.routes.url_helpers

    # class setting

    def default_url_options
      Rails.application.config.action_mailer.default_url_options
    end

    # routes, alphabetically
    def comment_target_path comment, title = false
      story_short_id_path(comment.story, title ? {title: comment.story.title_as_slug} : nil, anchor: "c_#{comment.short_id}")
    end

    def comment_target_url comment, title = false
      story_short_id_url(comment.story, title ? {title: comment.story.title_as_slug} : nil, anchor: "c_#{comment.short_id}")
    end

    def story_title_path story
      story_short_id_path(story, title: story.title_as_slug)
    end

    def story_title_url story
      story_short_id_url(story, title: story.title_as_slug)
    end

    def story_url_or_comments_path story
      story.url.presence || story_title_path(story)
    end

    def story_url_or_comments_url story
      story.url.presence || story_title_url(story)
    end
  end
end

# todo:
# routes
# other hacky model methods
# x story.url_or_comments_url, url_or_comments_path
# x story.comments_url
# x story.comments_path (is the route with the title on it)
# x story.short_id_url, short_id_path
# x comment.short_id_url, short_id_path
# x comment.path
# x comment.url
# x message.url (no path)
#   url_for
#   link_to
#   rename Routes.story_title_url/_path to just title_url? seems redundant
#   merged stories: anchor to :target _singledetail for highlight
#   ModNote: update use of Rails.application...
#   don't forget to run tests...
