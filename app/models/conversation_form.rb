class ConversationForm
  include ActiveModel::Model
  extend ActiveModel::Naming
  attr_accessor :username, :subject, :body, :hat_id, :mod_note
  attr_accessor :conversation, :author
  attr_reader :message_form

  delegate :to_param, :model_name, :persisted?, to: :conversation

  def initialize(attributes = {})
    super
    @conversation = build_conversation
    @message_form = MessageForm.new(message_params)
  end

  def save
    Conversation.transaction do
      if valid?
        conversation.save!
        message_form.save
      else
        self.errors.merge!(conversation.errors)
        self.errors.merge!(message_form.errors)
        false
      end
      conversation
    end
  end

  def valid?
    conversation.valid? && message_form.valid?
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
      body: body,
      hat_id: hat_id,
      mod_note: mod_note,
    }
  end
end
