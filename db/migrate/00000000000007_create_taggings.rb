class CreateTaggings < ActiveRecord::Migration[4.2]
  def change
    create_table "taggings", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.bigint "story_id", null: false, unsigned: true
      t.bigint "tag_id", null: false, unsigned: true
      t.index ["story_id", "tag_id"], name: "story_id_tag_id", unique: true
      t.index ["tag_id"], name: "taggings_tag_id_fk"
    end
  end
end
