class AddAnnouncementForComments < ActiveRecord::Migration[5.1]
  def change
    add_column :comment, :announcement, :boolean, :default => false
    add_column :comment, :announcement_child, :boolean, :default => false
  end
end
