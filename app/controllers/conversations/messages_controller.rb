module Conversations
  class MessagesController < ApplicationController
    def create
      @message = MessageCreator.create(
        conversation: conversation,
        author: @user,
        params: message_params
      )

      if @message.persisted?
        redirect_to conversation
      end
    end

  private

    def message_params
      params.require(:message).permit(:body, :hat_id, :mod_note)
    end

    def conversation
      @conversation ||= Conversation.find_by(short_id: params[:conversation_id])
    end
  end
end
