class AddUserSettingShowPreview < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :show_story_previews, :boolean, :default => false
  end
end
