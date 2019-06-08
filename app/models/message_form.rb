class MessageForm
  include ActiveModel::Model

  attr_accessor :body, :hat_id, :mod_note
  attr_accessor :conversation, :author
  attr_accessor :message

  delegate :errors, :persisted?, :valid?, to: :message

  def initialize(attributes = {})
    super
    @message = build_message
  end

  def save
    if valid?
      message.save!
    end
    message
  end

  def model_name
    ActiveModel::Name.new(Message)
  end

private

  def build_message
    Message.new(
      conversation: conversation,
      subject: conversation.subject,
      author: author,
      recipient: conversation.partner(of: author),
      body: body,
      hat_id: hat_id,
    ).tap do |message|
      if create_modnote? && author.is_moderator?
        ModNote.create_from_message(message, author)
      end
    end
  end

  def create_modnote?
    mod_note == "1"
  end
end
