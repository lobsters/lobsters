class ConversationsController < ApplicationController
  before_action :require_logged_in_user

  def index
    @conversations = find_user_conversations(@user).order(updated_at: :desc)
    @conversation = Conversation.new
  end

  def show
    @conversation = Conversation.find(params[:id])
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
      message_body: message_body,
    )
    if @conversation.persisted?
      redirect_to conversations_path
    else
      @conversations = find_user_conversations(@user)
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

  def message_body
    params[:message][:body]
  end

  def conversation_recipient
    params[:user][:username]
  end
end
