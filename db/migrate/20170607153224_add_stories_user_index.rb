class AddStoriesUserIndex < ActiveRecord::Migration
  def change
    add_index "stories", [ "user_id" ]
  end
end
