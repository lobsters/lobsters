class AddFullTextIndexToStoryCache < ActiveRecord::Migration[5.2]
  def change
    execute <<~SQL
    CREATE OR REPLACE FULLTEXT INDEX stories_story_cache ON stories(story_cache)
    SQL
  end
end
