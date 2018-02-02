class AddSubmitterIsAuthor < ActiveRecord::Migration[5.1]
  def change
    add_column :stories, :user_is_author, :boolean, :default => false
  end
end
