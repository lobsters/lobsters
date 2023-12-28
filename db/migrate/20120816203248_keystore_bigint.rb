class KeystoreBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :keystores, :value, :integer, limit: 8
  end

  def down
  end
end
