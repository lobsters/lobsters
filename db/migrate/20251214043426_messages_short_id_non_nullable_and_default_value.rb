class MessagesShortIdNonNullableAndDefaultValue < ActiveRecord::Migration[8.0]
  def change
    Message.where(short_id: nil).update_all(short_id: "")
    change_column_null :messages, :short_id, false
    change_column_default :messages, :short_id, from: nil, to: ""
  end
end
