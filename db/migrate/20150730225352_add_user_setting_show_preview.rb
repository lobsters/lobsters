class AddUserSettingShowPreview < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :show_story_previews, :boolean, :default => false
  end
end
