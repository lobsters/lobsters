class RecountStoriesDeleted < ActiveRecord::Migration[8.0]
  def up
    User.find_each(batch_size: 500, &:refresh_counts!)
  end

  def down
  end
end
