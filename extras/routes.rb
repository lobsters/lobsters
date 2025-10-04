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
      options = {anchor: "c_#{comment.short_id}"}
      story = comment.story.merged_into_story || comment.story
      options[:title] = story.title_as_slug if title
      story_short_id_path(story, options)
    end

    def comment_target_url comment, title = false
      options = {anchor: "c_#{comment.short_id}"}
      story = comment.story.merged_into_story || comment.story
      options[:title] = story.title_as_slug if title
      story_short_id_url(story, options)
    end

    def title_path story, anchor: nil
      story_short_id_path(story, title: story.title_as_slug, anchor:)
    end

    def title_url story, anchor: nil
      story_short_id_url(story, title: story.title_as_slug, anchor:)
    end

    def url_or_comments_path story, *options
      story.url.presence || title_path(story, *options)
    end

    def url_or_comments_url story, *options
      story.url.presence || title_url(story, *options)
    end
  end
end
