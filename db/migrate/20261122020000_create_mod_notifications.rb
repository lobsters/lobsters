class CreateModNotifications < ActiveRecord::Migration[8.1]
  def up
    create_table :mod_notifications do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :notifiable_type, null: false
      t.bigint :notifiable_id, null: false
      t.string :reason, null: false
      t.datetime :read_at
      t.string :token, null: false
      t.timestamps
    end
    add_index :mod_notifications, [:user_id, :notifiable_type, :notifiable_id, :reason], unique: true, name: "index_mod_notifications_uniqueness"
    add_index :mod_notifications, [:notifiable_type, :notifiable_id]
    add_index :mod_notifications, :token, unique: true
    add_index :mod_notifications, :created_at

    # backfill a year of notifications
    since = 1.year.ago
    now = Time.current
    items = Story.unmerged.where("flags > 1").where(created_at: since..).map { |s| [s, "flagged"] }
    items += Comment.mod_flagged.where(created_at: since..).map { |c| [c, "flagged"] }
    items += Comment.not_moderated
      .where.not(id: Comment.mod_flagged.select(:id))
      .where(created_at: since..)
      .where(id: HotspotDoc.hits.select(:comment_id))
      .map { |c| [c, "hotspot"] }

    rows = User.active.moderators.flat_map do |mod|
      items.map do |item, reason|
        {user_id: mod.id, notifiable_type: item.class.name, notifiable_id: item.id, reason: reason,
         read_at: now, token: TypeID.new("modnotification").to_s, created_at: item.created_at, updated_at: now}
      end
    end
    rows.each_slice(1_000) { |slice| ModNotification.insert_all(slice) }
  end

  def down
    drop_table :mod_notifications
  end
end
