class InactiveTags < ActiveRecord::Migration[5.1]
  def change
    add_column :tags, :inactive, :boolean, :default => false
  end
end
