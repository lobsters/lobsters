class InactiveTags < ActiveRecord::Migration
  def change
    add_column :tags, :inactive, :boolean, :default => false
  end
end
