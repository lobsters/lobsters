module ConversationHelper
  def conversation_status_classes(conversation)
    if conversation.unread?
      'unread'
    end
  end
end
