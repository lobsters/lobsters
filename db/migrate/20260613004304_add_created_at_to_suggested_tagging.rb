class AddCreatedAtToSuggestedTagging < ActiveRecord::Migration[8.0]
  def change
    add_timestamps :suggested_taggings, null: true
  end
end
