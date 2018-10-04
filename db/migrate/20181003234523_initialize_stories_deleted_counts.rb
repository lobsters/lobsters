class InitializeStoriesDeletedCounts < ActiveRecord::Migration[5.2]
  def up
    Keystore.transaction do
      User.pluck(:id).each do |user_id|
        Keystore.put(
          "user:#{user_id}:stories_deleted",
          Story.where(user_id: user_id).deleted.count
        )
      end
    end
  end

  def down
    condition = Keystore.arel_table[:key].matches("user:%:stories_deleted")

    Keystore.where(condition).delete_all
  end
end
