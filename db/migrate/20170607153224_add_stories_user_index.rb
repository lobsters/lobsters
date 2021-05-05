class AddStoriesUserIndex < ActiveRecord::Migration[6.0]
  def change
    add_index "stories", [ "user_id" ]
  end
end
