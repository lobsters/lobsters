class NormalizeUrl < ActiveRecord::Migration[7.0]
  def change
    add_column :stories, :normalized_url, :string, null: true, after: :url

    # this basic version takes 1789s in prod
    # Story.where("url != ''").find_each(batch_size: 500) do |story|
    #  story.normalized_url = Utils.normalize_url(story.url)
    #  story.save!(validate: false)
    # end

    # this optimized version takes 6s
    # user_id is unused but an insert couldn't succeed without it. 0 is a placehodler to be ignored
    # by not being mentioned in the 'on duplicate key' clause.
    Story.where("url != '' and url is not null").pluck(:id, :url).in_groups_of(1000, false).each do |group|
      group = group.map { |id, url| "(#{id}, \"#{Utils.normalize_url(url)}\", 0)" }.join(", ")
      ActiveRecord::Base.connection.execute <<~SQL
        insert into stories
          (id, normalized_url, user_id)
          values
          #{group}
        on duplicate key update normalized_url=VALUES(normalized_url);
      SQL
    end
    add_index :stories, :normalized_url
  end
end
