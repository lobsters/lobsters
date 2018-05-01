class AddUsedAtToInvitation < ActiveRecord::Migration[5.1]
  def change
    add_column :invitations, :used_at, :datetime, null: true, default: nil
  end
end
