class ChangeMailingListEnabled < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :mailing_list_enabled, :mailing_list_mode
    change_column :users, :mailing_list_mode, :integer, :default => 0
  end
end
