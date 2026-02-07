class DropWeblogs < ActiveRecord::Migration
  def change
    drop_table :weblogs
    remove_column :users, :weblog_feed_url
  end
end
