class KeystoreBigint < ActiveRecord::Migration[4.2]
  def up
    change_column :keystores, :value, :integer, :limit => 8
  end

  def down
  end
end
