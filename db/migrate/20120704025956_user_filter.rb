class UserFilter < ActiveRecord::Migration
  def up
    create_table :tag_filters do |t|
      t.timestamps
      t.integer :user_id
      t.integer :tag_id
    end
  end

  def down
  end
end
