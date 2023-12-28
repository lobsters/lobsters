class AddStoryUnavailable < ActiveRecord::Migration
  def change
    add_column :stories, :unavailable_at, :datetime
  end
end
