class ChangeMailingListEnabled < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :mailing_list_enabled
    add_column :users, :mailing_list_mode, :integer, :default => 0
  end
end
