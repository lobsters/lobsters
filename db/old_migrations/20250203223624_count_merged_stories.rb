class CountMergedStories < ActiveRecord::Migration[8.0]
  def up
    add_column :stories, :stories_count, :integer, null: false, default: 0
    Story.update_all("stories_count = (select count(*) from stories as s_inner where s_inner.merged_story_id = stories.id)")
  end

  def down
    remove_column :stories, :stories_count
  end
end
