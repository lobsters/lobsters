class DropWeblogs < ActiveRecord::Migration[4.2]
  def change
    drop_table :weblogs
    remove_column :users, :weblog_feed_url
  end
end
