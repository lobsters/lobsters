class AddUserWeblogUrl < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :weblog_feed_url, :string, :length => 500
  end
end
