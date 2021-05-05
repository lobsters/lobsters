class ModlogHatUse < ActiveRecord::Migration[6.0]
  def change
    add_column :hats, :modlog_use, :boolean, :default => false
    add_index :moderations, :created_at
  end
end
