class Conversations::MessagesController < ApplicationController
  def create
    @message = MessageCreator.create(
      conversation: conversation,
      author: @user,
      body: params[:message][:body],
      hat_id: params[:message][:hat_id],
    )

    if @message.persisted?
      redirect_to conversation
    end
  end

  private

  def message_params
    params.require(:message).permit(:body, :hat_id)
  end

  def conversation
    @conversation ||= Conversation.find_by(short_id: params[:conversation_id])
  end
end
