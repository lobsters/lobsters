class AddModerationLog < ActiveRecord::Migration[5.1]
  def up
    add_column "users", "is_moderator", :boolean, :default => false

    create_table "moderations" do |t|
      t.timestamps :null => false
      t.integer "moderator_user_id"
      t.integer "story_id"
      t.integer "comment_id"
      t.integer "user_id"
      t.text "action"
      t.text "reason"
    end
  end

  def down
  end
end
