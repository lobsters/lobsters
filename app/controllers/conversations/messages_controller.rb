module Conversations
  class MessagesController < ApplicationController
    before_action :require_logged_in_user
    before_action :require_logged_in_moderator, :mod_note

    def create
      @conversation = find_conversation
      @message = @conversation.messages.build(
        author: @user,
        recipient: @conversation.partner(of: @user),
      )
      @message.update(message_params)
      @message.hat = nil if @message.hat.try(:user_id) != @user.id

      if @message.save?
        if @user.is_moderator? && @message.mod_note
          ModNote.create_from_message(@new_message, @user)
        end
        redirect_to @conversation, flash: { success: "Message sent." }
      else
        render "conversations/show"
      end
    end

    def mod_note
      @message = Message.find(params[:message_id])
      ModNote.create_from_message(@message, @user)
      return redirect_to conversation_path(params[:conversation_id]), notice: 'ModNote created'
    end

  private

    def message_params
      params
        .require(:message)
        .permit(:body, :hat_id, @user.is_moderator? ? :mod_note : nil)
        .merge(author: @user)
    end

    def find_conversation
      Conversation.find_by(short_id: params[:conversation_id])
    end
  end
end
