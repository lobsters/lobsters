class AddSubmitterIsAuthor < ActiveRecord::Migration[7.1]
  def change
    add_column :stories, :user_is_author, :boolean, default: false
  end
end
