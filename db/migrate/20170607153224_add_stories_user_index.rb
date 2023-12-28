class AddStoriesUserIndex < ActiveRecord::Migration[7.1]
  def change
    add_index "stories", ["user_id"]
  end
end
