class AddCommentStats < ActiveRecord::Migration[7.2]
  def up
    create_table :comment_stats do |t|
      t.date :date, null: false
      t.integer :average, null: false
    end
    add_index :comment_stats, :date, unique: true

    Comment.connection.execute <<~SQL
      insert low_priority into comment_stats (`date`, `average`)
      select date(created_at - interval 5 hour) as date, avg(score) from comments group by date(created_at - interval 5 hour)
    SQL
  end

  def down
    drop_table :comment_stats
  end
end
