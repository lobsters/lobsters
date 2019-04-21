class ConversationsController < ApplicationController
  before_action :require_logged_in_user

  def index
    @conversations = find_user_conversations(@user).order(updated_at: :desc)
    @conversation = Conversation.new
  end

  def show
    @conversation = Conversation.
      includes(messages: [:author, :hat]).
      find_by(short_id: params[:id])
    @conversation.
      messages.
      where(recipient: @user).
      update_all(has_been_read: true)
    @user.update_unread_message_count!
    @message = Message.new(conversation: @conversation)
  end

  def create
    @conversation = ConversationCreator.create(
      author: @user,
      recipient_username: conversation_recipient,
      subject: conversation_subject,
      message_params: message_params,
    )
    if @conversation.persisted?
      redirect_to conversation_path(@conversation)
    else
      @conversations = find_user_conversations(@user).order(updated_at: :desc)
      render :index
    end
  end

  private

  def find_user_conversations(user)
    @conversations = Conversation.includes(:recipient, :author).involving(user)
  end

  def conversation_subject
    params[:conversation][:subject]
  end

  def message_params
    params.require(:message).permit(:body, :hat_id)
  end

  def conversation_recipient
    params[:user][:username]
  end
end
