class CreateKeystores < ActiveRecord::Migration[4.2]
  def change
    create_table "keystores", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "key", limit: 50, default: "", null: false
      t.bigint "value"
      t.index ["key"], name: "key", unique: true
    end
  end
end
