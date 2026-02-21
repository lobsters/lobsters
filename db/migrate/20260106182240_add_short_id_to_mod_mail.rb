class AddShortIdToModMail < ActiveRecord::Migration[8.0]
  def change
    add_column :mod_mails, :short_id, :string, null: false, limit: 10
    add_index :mod_mails, :short_id, unique: true
  end
end
