class AddStoryUnavailable < ActiveRecord::Migration[4.2]
  def change
    add_column :stories, :unavailable_at, :datetime
  end
end
