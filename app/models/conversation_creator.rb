class ConversationCreator
  def self.create(author:, recipient_username:, subject:, message_params: nil)
    new.create(
      author: author,
      recipient_username: recipient_username,
      subject: subject,
      message_params: message_params,
    )
  end

  def create(author:, recipient_username:, subject:, message_params: nil)
    conversation = Conversation.create(
      author: author,
      recipient: recipient(recipient_username),
      subject: subject,
    ).tap do |conversation|
      ensure_recipient(conversation: conversation, username: recipient_username)
      if conversation.persisted?
        MessageCreator.create(
          conversation: conversation,
          author: author,
          body: message_params[:body],
          hat_id: message_params[:hat_id],
        )
      end
    end
  end

  private

  def recipient(username)
    @_recipient ||= User.find_by(username: username)
  end

  def ensure_recipient(conversation:, username:)
    if conversation.recipient.nil?
      conversation.errors.add(:user, "Can't find user: #{username}")
    end
  end
end
