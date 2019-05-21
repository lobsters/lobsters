module ConversationHelper
  def conversation_status_classes(conversation)
    if conversation.messages.unread.any?
      'unread'
    end
  end
end
