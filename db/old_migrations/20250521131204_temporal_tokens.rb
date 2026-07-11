class TemporalTokens < ActiveRecord::Migration[8.0]
  disable_ddl_transaction! # took ~75 min in dev, prod will be similar

  def up
    # dropping because these lack identity, they're dropped and recreated on edit
    remove_column :links, :token

    # backfill missing tags timestamps
    add_column :tags, :created_at, :datetime
    add_column :tags, :updated_at, :datetime
    Tag.all.find_each do |tag|
      first_use = tag.stories.order(created_at: :asc).pick(:created_at)
      latest_edit = Moderation.where(tag: tag).order(created_at: :desc).pick(:created_at)
      tag.update_columns({
        created_at: first_use || Time.current,
        updated_at: latest_edit || first_use || Time.current
      })
    end
    change_column :tags, :created_at, :datetime, null: false
    change_column :tags, :updated_at, :datetime, null: false

    # typeid tokens should've used the record timestamp, realized when I worked with them a bit and
    # saw prefix_01jt8 everywhere
    [
      Category,
      Comment,
      Domain,
      Hat,
      HatRequest,
      HiddenStory,
      Invitation,
      InvitationRequest,
      Message,
      Moderation,
      ModNote,
      Origin,
      SavedStory,
      Story,
      Tag,
      User
    ].each do |model|
      Rails.logger.warn "#{model} #{model.all.count}"
      model.all.select(:id, :created_at).find_each do |record|
        timestamp = record.created_at.to_i * 1000 + rand(1000) # invent milliseconds
        record.update_column :token, TypeID.new(model.to_s.parameterize, timestamp:)
      end
    end
  end

  def down
    add_column :links, :token, :varchar, null: false
    remove_column :tags, :created_at
    remove_column :tags, :updated_at
  end
end
