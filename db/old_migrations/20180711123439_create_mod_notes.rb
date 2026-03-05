class CreateModNotes < ActiveRecord::Migration[5.2]
  def change
    create_table :mod_notes do |t|
      t.integer :moderator_user_id, null: false
      t.integer :user_id, null: false
      t.text :note, null: false
      t.text :markeddown_note, null: false
      t.datetime :created_at, null: false
    end

    add_index :mod_notes, [:id, :user_id]
  end
end
