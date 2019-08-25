class ConversationsController < ApplicationController
  before_action :require_logged_in_user

  def index
    @conversations = find_user_conversations(@user).order(updated_at: :desc)
    @conversation_form = ConversationForm.new(username: params[:to])
  end

  def show
    @conversation = Conversation
      .includes(messages: [:author, :hat])
      .find_by(short_id: params[:id])
    @heading = @conversation.subject
    @conversation
      .messages
      .where(recipient: @user)
      .update_all(has_been_read: true)
    @user.update_unread_message_count!
    @message = Message.new(conversation: @conversation, author: @user)
  end

  def create
    @conversation_form = ConversationForm.new(conversation_form_params)
    @conversation_form.save

    if @conversation_form.persisted?
      redirect_to conversation_path(@conversation_form), flash: { success: "Conversation started." }
    else
      @conversations = find_user_conversations(@user).order(updated_at: :desc)
      render :index
    end
  end

  def destroy
    @conversation = find_user_conversations(@user)
      .find_by(short_id: params[:id])

    if @conversation.present?
      if @conversation.author == @user
        @conversation.update(deleted_by_author_at: Time.zone.now)
      else
        @conversation.update(deleted_by_recipient_at: Time.zone.now)
      end
      redirect_to conversations_path, flash: { success: "Deleted conversation." }
    else
      flash[:error] = "Could not delete message"
      redirect_to conversation_path(@conversation)
    end
  end

private

  def conversation_form_params
    params
      .require(:conversation)
      .permit(:username, :subject, :body, :hat_id, :mod_note)
      .merge(author: @user)
  end

  def find_user_conversations(user)
    @conversations = Conversation.includes(:recipient, :author).involving(user)
  end

  def conversation_subject
    params[:conversation][:subject]
  end

  def conversation_recipient
    params[:conversation][:username]
  end
end
