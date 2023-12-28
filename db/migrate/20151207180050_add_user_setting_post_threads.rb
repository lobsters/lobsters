class AddUserSettingPostThreads < ActiveRecord::Migration[7.1]
  def change
    add_column "users", "show_submitted_story_threads", :boolean,
      default: true
  end
end
