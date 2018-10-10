class AddStoriesUserIndex < ActiveRecord::Migration[4.2]
  def change
    add_index "stories", [ "user_id" ]
  end
end
