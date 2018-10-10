class PrivateRssFeed < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :rss_token, :string, collation: "utf8mb4_general_ci"
  end

  def down
    remove_column :users, :rss_token
  end
end
