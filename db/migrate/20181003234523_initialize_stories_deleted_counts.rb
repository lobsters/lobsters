class InitializeStoriesDeletedCounts < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.connection.execute <<~SQL
      replace low_priority into keystores
      select concat("user:", users.id, ":stories_deleted"), 0
      from users left join stories on users.id = stories.user_id where stories.id is null;
      
      replace low_priority into keystores
      select concat("user:", users.id, ":stories_deleted"),  count(*)
      from users left join stories on users.id = stories.user_id
      where stories.is_expired = true group by users.id;
    SQL
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
