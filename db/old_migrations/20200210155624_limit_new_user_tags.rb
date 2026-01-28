class LimitNewUserTags < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :permit_by_new_users, :boolean, null: false, default: true
  end
end
