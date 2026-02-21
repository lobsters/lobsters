class CreateUsernames < ActiveRecord::Migration[8.0]
  def up
    create_table :usernames do |t|
      t.string :username, null: false
      t.bigint :user_id, null: false
      t.datetime :created_at, null: false
      t.datetime :renamed_away_at
    end

    # only 19k users, just doing the easy thing here
    User.order(id: :asc).find_each do |user|
      renames = Moderation.where(user_id: user.id).where('action like "%changed own username from %"').order(created_at: :asc).to_a

      if renames.empty?
        # no renames, record their in-use username
        Username.insert!({
          user_id: user.id,
          username: user.username,
          created_at: user.created_at,
          renamed_away_at: nil
        }, returning: nil, record_timestamps: false)
      else
        started_using_username = user.created_at
        current_username = nil
        renames.zip(renames[1..]).each do |rename, next_rename|
          match = rename.action.match(/changed own username from "([^"]+)" to "([^"]+)"/)
          old_username = match[1]
          new_username = match[2]

          Username.insert!({
            user_id: user.id,
            username: old_username,
            created_at: started_using_username,
            renamed_away_at: rename&.created_at
          }, returning: nil, record_timestamps: false)
          started_using_username = rename.created_at
          current_username = new_username
        end

        Username.insert!({
          user_id: user.id,
          username: current_username,
          created_at: started_using_username,
          renamed_away_at: nil
        }, returning: nil, record_timestamps: false)
      end
    end

    # fix up the one troll who tried to troll by renaming to something offensive
    if (u = User.find_by(username: "asthma"))
      reset = Moderation.find(4104)
      username = u.usernames.last
      username.renamed_away_at = reset.created_at
      username.save!
      u.usernames.create!({
        username: "asthma",
        created_at: reset.created_at,
        renamed_away_at: nil
      })
    end
  end

  def down
    drop_table :usernames
  end
end
