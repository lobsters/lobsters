class AddIndexForModerationsAssociatedModel < ActiveRecord::Migration[5.2]
  def change
    add_index :moderations, :user_id
  end
end
