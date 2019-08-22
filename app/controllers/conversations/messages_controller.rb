module Conversations
  class MessagesController < ApplicationController
    def create
      @conversation = find_conversation
      @message_form = MessageForm.new(
        message_params.merge(conversation: @conversation)
      )
      @message_form.save

      if @message_form.persisted?
        redirect_to @conversation, flash: { success: "Message sent." }
      else
        render "conversations/show"
      end
    end

  private

    def message_params
      params
        .require(:message)
        .permit(:body, :hat_id, :mod_note)
        .merge(author: @user)
    end

    def find_conversation
      Conversation.find_by(short_id: params[:conversation_id])
    end
  end
end
