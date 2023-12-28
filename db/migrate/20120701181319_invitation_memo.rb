class InvitationMemo < ActiveRecord::Migration[7.1]
  def up
    add_column :invitations, :memo, :text
  end

  def down
  end
end
