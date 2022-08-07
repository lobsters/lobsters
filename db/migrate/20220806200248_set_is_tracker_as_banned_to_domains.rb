class SetIsTrackerAsBannedToDomains < ActiveRecord::Migration[7.0]
  def up
    if ActiveRecord::Base.connection.column_exists?(:domains, :is_tracker)
      banned_by_user = User.find_by(username: 'pushcx')
      Domain.where(is_tracker: true).each do |domain|
        domain.ban_by_user_for_reason!(banned_by_user, 'Used for link shortening and ad tracking')
      end
    end
  end
end
