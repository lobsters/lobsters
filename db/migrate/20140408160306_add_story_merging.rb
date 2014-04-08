class AddStoryMerging < ActiveRecord::Migration
  def change
    add_column :stories, :merged_story_id, :integer
    add_index "stories", [ "merged_story_id" ]
  end
end
