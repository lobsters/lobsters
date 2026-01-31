class MessagesShortIdNonNullableAndDefaultValue < ActiveRecord::Migration[8.0]
  def change
    if Message.where(short_id: nil).exists?
      raise "One or more Messages with a nil short_id exist."
    end

    change_column_null :messages, :short_id, false
    change_column_default :messages, :short_id, from: nil, to: ""
  end
end
