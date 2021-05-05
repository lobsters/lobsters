class DropWeblogs < ActiveRecord::Migration[6.0]
  def change
    drop_table :weblogs
    remove_column :users, :weblog_feed_url
  end
end
