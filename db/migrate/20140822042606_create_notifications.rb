class CreateNotifications < ActiveRecord::Migration
  def change
    create_table "notifications" do |t|
        t.integer "user_id", null: false
        t.string "comment_id", null: false
        t.boolean "unread", null: false
        t.timestamps
    end

    add_index "notifications", ["user_id", "comment_id"], name: "unique_notification_id", using: :btree

    reversible do |dir|
      dir.up do
        Comment.all.each do |c|
          c.mentions.each do |mention|
            if u = User.where(:username => mention).first
              unless u.id == c.user_id
                unless Notification.where(:comment => c, :user => u).first
                  n = Notification.new
                  n.comment = c
                  n.user = u
                  n.unread = true
                  n.save
                end
              end
            end
          end
        end
      end
    end
  end
end
