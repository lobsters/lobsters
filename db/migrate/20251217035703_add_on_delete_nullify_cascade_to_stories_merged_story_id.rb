class AddOnDeleteNullifyCascadeToStoriesMergedStoryId < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :stories, :stories, column: :merged_story_id, name: "stories_merged_story_id_fk"

    add_foreign_key :stories, :stories,
      column: :merged_story_id,
      name: "stories_merged_story_id_fk",
      on_delete: :nullify
  end
end
