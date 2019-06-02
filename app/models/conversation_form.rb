class ConversationForm
  include ActiveModel::Model
  attr_accessor :conversation, :message_body, :username

  delegate :to_model, to: :conversation
end
