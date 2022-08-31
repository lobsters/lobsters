class SetIsTrackerAsBannedToDomains < ActiveRecord::Migration[7.0]
  def up
    banned_by_user = User.find_by(username: 'pushcx')
    Domain.where(is_tracker: true).each do |domain|
      domain.ban_by_user_for_reason!(banned_by_user, 'Used for link shortening and ad tracking')
    end

    remove_column :domains, :is_tracker, :boolean
  end
end
