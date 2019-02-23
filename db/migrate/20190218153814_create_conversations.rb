class CreateConversations < ActiveRecord::Migration[5.2]
  def change
    create_table :conversations do |t|
      t.timestamps
      t.string :short_id, null: false, unique: true
      t.string :subject, null: false
      t.belongs_to :author_user
      t.belongs_to :recipient_user
    end

    add_belongs_to :messages, :conversation
  end
end
