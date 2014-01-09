class KeystoreBigint < ActiveRecord::Migration
  def up
    change_column :keystores, :value, :integer, :limit => 8
  end

  def down
  end
end
