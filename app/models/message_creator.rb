class MessageCreator
  def self.create(conversation:, author:, body:, hat_id: nil)
    new.create(
      conversation: conversation,
      author: author,
      body: body,
      hat_id: hat_id,
    )
  end

  def create(conversation:, author:, body:, hat_id: nil)
    conversation.messages.create(
      subject: conversation.subject,
      author: author,
      recipient: conversation.partner(of: author),
      body: body,
      hat_id: hat_id,
    )
  end
end
