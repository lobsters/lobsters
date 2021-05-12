class AddIndexForModerationsAssociatedModel < ActiveRecord::Migration[6.0]
  def change
    add_index :moderations, :user_id
  end
end
