class CreateTags < ActiveRecord::Migration[4.2]
  def change
    create_table "tags", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "tag", limit: 25, null: false
      t.string "description", limit: 100
      t.index ["tag"], name: "tag", unique: true
    end
  end
end
