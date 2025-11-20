class AddGrantedModeratorAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :granted_moderator_at, :datetime, null: true, default: nil

    User.order(id: :asc).find_each do |user|
      granted_moderator_at = Moderation.where(user_id: user.id).where('action like "%Granted moderator status%"').order(created_at: :asc).first

      if granted_moderator_at.present?
        User.update!(user.id, granted_moderator_at: granted_moderator_at.created_at)
      end
    end
  end
end
