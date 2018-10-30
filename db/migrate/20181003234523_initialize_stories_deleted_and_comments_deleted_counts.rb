class InitializeStoriesDeletedAndCommentsDeletedCounts < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.connection.execute <<~SQL
      -- initialize stories_deleted counts
      replace low_priority into keystores
      select concat("user:", users.id, ":stories_deleted"), 0
      from users left join stories on users.id = stories.user_id where stories.id is null;

      replace low_priority into keystores
      select concat("user:", users.id, ":stories_deleted"),  count(*)
      from users left join stories on users.id = stories.user_id
      where stories.is_expired = true group by users.id;

      -- initialize comments_deleted counts
      replace low_priority into keystores
      select concat("user:", users.id, ":comments_deleted"), 0
      from users left join comments on users.id = comments.user_id where comments.user_id is null;

      replace low_priority into keystores
      select concat("user:", users.id, ":comments_deleted"),  count(*)
      from users left join comments on users.id = comments.user_id
      where comments.is_deleted = true group by users.id;
    SQL
  end

  def down
    ActiveRecord::Base.connection.execute <<~SQL
      delete from keystores where `key` like 'user:%:stories_deleted';
      delete from keystores where `key` like 'user:%:comments_deleted';
    SQL
  end
end
