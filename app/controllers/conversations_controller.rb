class ConversationsController < ApplicationController
  before_action :require_logged_in_user

  def index
    @conversations = Conversation.includes(:recipient, :author).involving(@user)
    @conversation = Conversation.new
  end

  def show
    @conversation = Conversation.find(params[:id])
    @conversation.
      messages.
      where(recipient: @user).
      update_all(has_been_read: true)
    @user.update_unread_message_count!
  end

  def create
    @conversation = Conversation.new(
      conversation_params.
        merge(conversation_user_params).
        merge(author: @user)
    )
    if @conversation.save
      @conversation.messages.create(
        message_params.merge(
          subject: @conversation.subject,
          author: @conversation.author,
          recipient: @conversation.recipient
        )
      )
      redirect_to conversations_path
    end
  end

  private

  def conversation_params
    params.require(:conversation).permit(:subject)
  end

  def message_params
    params.require(:message).permit(:body)
  end

  def conversation_user_params
    user_params = params.require(:user).permit(:username)
    if user = User.find_by(username: user_params[:username])
      { recipient: user }
    else
      @conversation.errors.add(
        :recipient,
        "Can't find user: #{user_params[:username]}"
      )
      {}
    end
  end
end
