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
  end

  def down
    ActiveRecord::Base.connection.execute <<~SQL
      delete from keystores where `key` like 'user:%:stories_deleted';
    SQL
  end
end
