class FixUpMessages < ActiveRecord::Migration
  def up
    rename_column :messages, :random_hash, :short_id

    add_column :messages, :deleted_by_author, :boolean, :default => false
    add_column :messages, :deleted_by_recipient, :boolean, :default => false
  end

  def down
  end
end
