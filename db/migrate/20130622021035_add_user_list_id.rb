class AddUserListId < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :mailing_list_token, :string
    add_column :users, :mailing_list_enabled, :boolean, :default => false

    add_index "users", [ "mailing_list_enabled" ]
  end

  def down
    remove_column :users, :mailing_list_token
    remove_column :users, :mailing_list_enabled
  end
end
