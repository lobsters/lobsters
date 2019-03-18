class Conversations::MessagesController < ApplicationController
  def create
    @message = conversation.messages.new(
      message_params.merge(
        author: conversation.author,
        recipient: conversation.recipient,
        subject: conversation.subject,
      ),
    )

    if @message.save
      redirect_to conversation
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end

  def conversation
    @conversation ||= Conversation.find(params[:conversation_id])
  end
end
