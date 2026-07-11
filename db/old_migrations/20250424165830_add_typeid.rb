class AddTypeid < ActiveRecord::Migration[8.0]
  disable_ddl_transaction! # took ~75 min in dev, prod will be similar

  def up
    [
      Category,
      Comment,
      Domain,
      Hat,
      HatRequest,
      HiddenStory,
      Invitation,
      InvitationRequest,
      Link,
      Message,
      Moderation,
      ModNote,
      Origin,
      SavedStory,
      Story,
      Tag,
      User
    ].each do |model|
      add_column model.table_name, :slug, :string, default: nil
      model.find_each { |m| m.update_column :slug, TypeID.new(model.to_s.parameterize) }
      change_column model.table_name, :slug, :string, default: nil, null: false
      add_index model.table_name, :slug, unique: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
