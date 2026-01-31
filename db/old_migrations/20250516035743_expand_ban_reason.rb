class ExpandBanReason < ActiveRecord::Migration[8.0]
  def up
    change_column :users, :banned_reason, :string, limit: 256
  end

  def down
    change_column :users, :banned_reason, :string, limit: 200
  end
end
