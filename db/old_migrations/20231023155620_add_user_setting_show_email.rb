class AddUserSettingShowEmail < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :show_email, :boolean, default: false, null: false
  end
end
