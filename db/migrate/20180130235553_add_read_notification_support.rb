class AddReadNotificationSupport < ActiveRecord::Migration[5.1]
  def change
    create_table :read_ribbons, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.boolean :is_following, default: true
      t.timestamps
    end

    add_reference :read_ribbons, :user, index: true
    add_reference :read_ribbons, :story, index: true

    create_view :replying_comments
  end
end
