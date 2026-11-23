class BackfillStoryTexts < ActiveRecord::Migration[8.1]
  def up
    Story.where.missing(:story_text).order(id: :desc).each_with_index do |story, i|
      # don't hammer the shit out of diffbot
      SyncStoryTextJob.set(wait: i.seconds).perform_later(story)
    end
  end

  def down
  end
end
