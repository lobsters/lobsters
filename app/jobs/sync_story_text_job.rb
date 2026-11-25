class SyncStoryTextJob < ApplicationJob
  queue_as :default
  # Diffbot does 2 requests with this timeout, but typically finishes in a couple seconds
  limits_concurrency to: 1, key: ->(story) { story.id }, duration: Diffbot::TIMEOUT.seconds

  def perform(story)
    StoryText.sync!(story)
  end
end
