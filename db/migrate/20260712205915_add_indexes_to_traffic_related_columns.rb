class AddIndexesToTrafficRelatedColumns < ActiveRecord::Migration[8.0]
  def change
    # Used by TrafficHelper.traffic_range
    add_index :comments, "floor(unixepoch(created_at)/900), created_at", name: "index_comments_on_period_and_created_at"
    add_index :stories, "floor(unixepoch(created_at)/900), created_at", name: "index_stories_on_period_and_created_at"
    add_index :votes, "floor(unixepoch(updated_at)/900), updated_at", name: "index_votes_on_period_and_updated_at"

    # Used by TrafficHelper.current_activity!
    add_index :comments, :created_at
    add_index :votes, :updated_at
  end
end
