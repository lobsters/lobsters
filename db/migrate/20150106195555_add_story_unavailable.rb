class AddStoryUnavailable < ActiveRecord::Migration[7.1]
  def change
    add_column :stories, :unavailable_at, :datetime
  end
end
