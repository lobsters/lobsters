class AddStoryAndUserToReadRibbon < ActiveRecord::Migration[5.1]
  def change
    add_reference :read_ribbons, :user, index: true
    add_reference :read_ribbons, :story, index: true
  end
end
