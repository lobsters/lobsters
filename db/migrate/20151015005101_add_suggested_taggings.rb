class AddSuggestedTaggings < ActiveRecord::Migration[4.2]
  def change
    create_table :suggested_taggings do |t|
      t.integer :story_id
      t.integer :tag_id
      t.integer :user_id
    end
  end
end
