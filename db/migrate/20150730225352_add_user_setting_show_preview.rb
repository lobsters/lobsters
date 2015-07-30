class AddUserSettingShowPreview < ActiveRecord::Migration
  def change
    add_column :users, :show_story_previews, :boolean, :default => false
  end
end
