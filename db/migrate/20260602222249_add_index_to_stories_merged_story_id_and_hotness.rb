class AddIndexToStoriesMergedStoryIdAndHotness < ActiveRecord::Migration[8.0]
  def change
    # takes the home#index story load query from half a second to less than a millisecond in development
    add_index :stories, [:merged_story_id, :hotness]
  end
end
