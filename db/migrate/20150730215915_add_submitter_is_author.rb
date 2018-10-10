class AddSubmitterIsAuthor < ActiveRecord::Migration[4.2]
  def change
    add_column :stories, :user_is_author, :boolean, :default => false
  end
end
