class LimitNewUserTags < ActiveRecord::Migration[6.0]
  def change
    add_column :tags, :permit_by_new_users, :boolean, null: false, default: true
  end
end
