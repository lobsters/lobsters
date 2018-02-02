class AddDisabledInvitesToUsers < ActiveRecord::Migration[5.1]
  def change
      add_column :users, :disabled_invite_at, :datetime
      add_column :users, :disabled_invite_by_user_id, :integer
      add_column :users, :disabled_invite_reason, :string, {limit: 200}
  end
end
