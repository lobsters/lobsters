class MessageCreator
  def self.create(conversation:, author:, body:)
    new.create(conversation: conversation, author: author, body: body)
  end

  def create(conversation:, author:, body:)
    conversation.messages.create(
      subject: conversation.subject,
      author: author,
      recipient: conversation.partner(of: author),
      body: body,
    )
  end
end
