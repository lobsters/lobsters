class KeystoreBigint < ActiveRecord::Migration[5.1]
  def up
    change_column :keystores, :value, :integer, :limit => 8
  end

  def down
  end
end
