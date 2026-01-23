class CreateStoryCardJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(story) { story.short_id }, duration: 5.minutes

  def perform(story)
    StoryImage.new(story).generate(story.url)
  end
end
