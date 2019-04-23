class CreateConversations < ActiveRecord::Migration[5.2]
  def up
    create_table :conversations do |t|
      t.timestamps
      t.string :short_id, null: false, unique: true
      t.string :subject, null: false
      t.belongs_to :author_user, null: false
      t.belongs_to :recipient_user, null: false
      t.datetime :deleted_by_author_at
      t.datetime :deleted_by_recipient_at
    end

    add_belongs_to :messages, :conversation, null: true

    MessageConverter.new.run

    change_column_null :messages, :conversation_id, false
    add_foreign_key :messages, :conversations, column: :conversation_id, name: "messages_conversation_id_fk"
  end

  def down
    remove_belongs_to :messages, :conversation
    drop_table :conversations
  end
end

class MessageConverter
  include ActiveRecord::ConnectionAdapters::Quoting

  attr_reader :mysql

  def initialize
    config = ActiveRecord::Base.configurations[Rails.env].symbolize_keys
    @mysql = ActiveRecord::Base.connection
  end

  def run
    begin
      grouped_messages = group_messages(messages_with_partner_combo)
      conversation_values = grouped_messages.map do |group|
        messages = group.last
        values = conversation_data(messages).join(",")
        "(" + values + ")"
      end.join(",")

      create_conversations(conversation_values, mysql)

      grouped_messages.map do |group|
        message_ids = group.last.map { |message| message["id"] }.join(", ")
        short_id = conversation_data(group.last)[2]
        conversation_ids = mysql.exec_query <<~SQL
          SELECT id FROM conversations
          WHERE short_id = #{short_id}
        SQL
        conversation_id = conversation_ids.first["id"]

        mysql.exec_query <<~SQL
          UPDATE messages
          SET conversation_id = #{conversation_id}
          WHERE id IN (#{message_ids})
        SQL
      end
    rescue => e
      mysql.exec_query("DELETE FROM conversations")
      mysql.exec_query("UPDATE messages SET conversation_id = NULL")
      puts e
      puts caller
    end
  end

  def messages_with_partner_combo
    mysql.exec_query <<~SQL
      SELECT *,
      (CASE WHEN author_user_id < recipient_user_id
        THEN CONCAT(author_user_id, '-', recipient_user_id)
        ELSE CONCAT(recipient_user_id, '-', author_user_id)
      END) AS partners
      FROM messages
    SQL
  end

  def group_messages(messages)
    messages.group_by do |message|
      normalized_subject = message["subject"].sub(/Re: /, '')
      "#{normalized_subject}#{message["partners"]}"
    end
  end

  def conversation_data(messages)
    [
      quote(messages.first["created_at"]),
      quote(messages.last["created_at"]),
      quote(messages.first["short_id"]),
      quote(messages.first["subject"]),
      messages.first["author_user_id"],
      messages.first["recipient_user_id"],
      quote(author_deleted_at(messages)),
      quote(recipient_deleted_at(messages)),
    ]
  end

  def author_deleted_at(messages)
    deleted_message = messages.
      select{ |message| message["deleted_by_author"] == 1 }.
      last
    deleted_message&.dig("created_at")
  end

  def recipient_deleted_at(messages)
    deleted_message = messages.
      select{ |message| message["deleted_by_recipient"] == 1 }.
      last
    deleted_message&.dig("created_at")
  end

  def create_conversations(values, mysql)
    puts "create conversations"
    mysql.exec_query <<~SQL
      INSERT INTO conversations
      (created_at, updated_at, short_id, subject, author_user_id, recipient_user_id, deleted_by_author_at, deleted_by_recipient_at)
      VALUES #{values}
    SQL
  end
end
