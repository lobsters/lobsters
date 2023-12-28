class ModerationsFromGroup < ActiveRecord::Migration[7.1]
  def change
    add_column :moderations, :is_from_suggestions, :boolean, default: false
  end
end
