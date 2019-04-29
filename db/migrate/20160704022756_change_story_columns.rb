class ChangeStoryColumns < ActiveRecord::Migration[4.2]
  def change
    change_column :stories, :is_moderated, :boolean, default: false, null: false
    change_column :stories, :is_expired, :boolean, default: false, null: false
  end
end
