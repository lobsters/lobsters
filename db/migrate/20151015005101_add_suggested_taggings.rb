class AddSuggestedTaggings < ActiveRecord::Migration[5.1]
  def change
    create_table :suggested_taggings do |t|
      t.integer :story_id
      t.integer :tag_id
      t.integer :user_id
    end
  end
end
