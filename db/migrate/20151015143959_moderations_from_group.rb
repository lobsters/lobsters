class ModerationsFromGroup < ActiveRecord::Migration
  def change
    add_column :moderations, :is_from_suggestions, :boolean, :default => false
  end
end
