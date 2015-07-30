class AddSubmitterIsAuthor < ActiveRecord::Migration
  def change
    add_column :stories, :user_is_author, :boolean, :default => false
  end
end
