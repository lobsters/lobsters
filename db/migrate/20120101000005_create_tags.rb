class CreateTags < ActiveRecord::Migration[4.2]
  def change
    create_table :tags do |t|
        t.string "tag", limit: 25, null: false
        t.string "description", limit: 100
        t.index ["tag"], name: "tag", unique: true
        t.timestamps
    end
  end
end
