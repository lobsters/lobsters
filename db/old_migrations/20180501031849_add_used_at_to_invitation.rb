class AddUsedAtToInvitation < ActiveRecord::Migration[5.1]
  def change
    change_column :invitations, :user_id, :integer, null: false
    add_column :invitations, :used_at, :datetime, null: true, default: nil
    add_column :invitations, :new_user_id, :integer, null: true, default: nil
  end
end
