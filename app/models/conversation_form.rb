class ConversationForm
  include ActiveModel::Model
  extend ActiveModel::Naming
  attr_accessor :username, :subject, :body, :hat_id, :mod_note
  attr_accessor :conversation, :author
  attr_reader :message

  delegate :to_param, :model_name, :persisted?, to: :conversation

  def initialize(attributes = {})
    super
    @conversation = build_conversation
    @message = Message.new(message_params)
    @message.hat = nil if @message.hat.try(:user_id) != author.id
  end

  def save
    Conversation.transaction do
      if valid?
        conversation.save!
        message.save!
        if author.is_moderator? && @message.mod_note
          ModNote.create_from_message(@message, author)
        end
      else
        self.errors.merge!(conversation.errors)
        self.errors.merge!(message.errors)
        false
      end
      conversation
    end
  end

  def valid?
    conversation.valid? && message.valid?
  end

private

  def build_conversation
    @conversation = Conversation.new(
      author: author,
      recipient: recipient(username),
      subject: subject,
    )
  end

  def recipient(username)
    User.find_by(username: username)
  end

  def message_params
    {
      conversation: conversation,
      author: author,
      recipient: recipient(username),
      body: body,
      hat_id: hat_id,
      mod_note: mod_note,
    }
  end
end
