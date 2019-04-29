class CreateTaggings < ActiveRecord::Migration[4.2]
  def change
    create_table :taggings do |t|
      t.integer "story_id", null: false, unsigned: true
      t.integer "tag_id", null: false, unsigned: true
      t.index ["story_id", "tag_id"], name: "story_id_tag_id", unique: true
    end
  end
end
