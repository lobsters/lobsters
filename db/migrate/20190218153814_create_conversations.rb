class CreateConversations < ActiveRecord::Migration[5.2]
  def change
    create_table :conversations do |t|
      t.timestamps
      t.belongs_to :author_user
      t.belongs_to :recipient_user
    end

    add_belongs_to :messages, :conversation
  end
end
