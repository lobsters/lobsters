class ConversationCreator
  def self.create(author:, recipient_username:, subject:, message_body:)
    new.create(
      author: author,
      recipient_username: recipient_username,
      subject: subject,
      message_body: message_body,
    )
  end

  def create(author:, recipient_username:, subject:, message_body:)
    conversation = Conversation.create(
      author: author,
      recipient: recipient(recipient_username),
      subject: subject,
    ).tap do |conversation|
      ensure_recipient(conversation: conversation, username: recipient_username)
      if conversation.persisted?
        conversation.messages.create(
          subject: conversation.subject,
          author: conversation.author,
          recipient: conversation.recipient,
          body: message_body,
        )
      end
    end
  end

  private

  def recipient(username)
    @_recipient ||= User.find_by(username: username)
  end

  def ensure_recipient(conversation: conversation, username: username)
    if conversation.recipient.nil?
      conversation.errors.add(:user, "Can't find user: #{username}")
    end
  end
end
