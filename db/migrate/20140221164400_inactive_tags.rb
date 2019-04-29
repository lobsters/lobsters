class InactiveTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :inactive, :boolean, :default => false
  end
end
