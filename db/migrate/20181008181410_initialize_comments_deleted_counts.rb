class InitializeCommentsDeletedCounts < ActiveRecord::Migration[5.2]
  def up
    Keystore.transaction do
      User.pluck(:id).each do |user_id|
        Keystore.put(
          "user:#{user_id}:comments_deleted",
          Comment.where(user_id: user_id, is_deleted: true).count
        )
      end
    end
  end

  def down
    condition = Keystore.arel_table[:key].matches("user:%:comments_deleted")

    Keystore.where(condition).delete_all
  end
end
