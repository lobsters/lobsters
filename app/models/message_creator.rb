class MessageCreator
  def self.create(
    conversation:,
    author:,
    body:,
    hat_id: nil,
    create_modnote: false
  )
    new.create(
      conversation: conversation,
      author: author,
      body: body,
      hat_id: hat_id,
      create_modnote: create_modnote
    )
  end

  def create(conversation:, author:, body:, hat_id: nil, create_modnote: false)
    conversation.messages.create(
      subject: conversation.subject,
      author: author,
      recipient: conversation.partner(of: author),
      body: body,
      hat_id: hat_id,
    ).tap do |message|
      if create_modnote
        ModNote.create_from_message(message, author)
      end
    end
  end
end
