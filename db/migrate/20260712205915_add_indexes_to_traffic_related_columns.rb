class AddIndexesToTrafficRelatedColumns < ActiveRecord::Migration[8.0]
  def change
    add_index :comments, :created_at
    add_index :votes, :updated_at
  end
end
