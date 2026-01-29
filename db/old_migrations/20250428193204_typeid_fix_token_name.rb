class TypeidFixTokenName < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
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
      rename_column model.table_name, :slug, :token
    end
  end
end
