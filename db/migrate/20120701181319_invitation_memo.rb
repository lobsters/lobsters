class InvitationMemo < ActiveRecord::Migration[6.0]
  def up
    add_column :invitations, :memo, :text
  end

  def down
  end
end
