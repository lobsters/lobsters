class ModerationsFromGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :moderations, :is_from_suggestions, :boolean, :default => false
  end
end
