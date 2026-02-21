class InvitationMemo < ActiveRecord::Migration
  def up
    add_column :invitations, :memo, :text
  end

  def down
  end
end
