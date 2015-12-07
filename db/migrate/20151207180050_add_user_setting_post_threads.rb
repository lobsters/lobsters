class AddUserSettingPostThreads < ActiveRecord::Migration
  def change
    add_column "users", "show_submitted_story_threads", :boolean,
      :default => true
  end
end
