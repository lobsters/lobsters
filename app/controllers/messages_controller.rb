class MessagesController < ApplicationController
  before_filter :require_logged_in_user
  before_filter :find_message, :only => [ :show, :destroy, :keep_as_new ]

  def index
    @new_message = Message.new

    if params[:to]
      @new_message.recipient_username = params[:to]
    end
  end

  def create
    @new_message = Message.new(params[:message])
    @new_message.author_user_id = @user.id

    if @new_message.save
      flash.now[:success] = "Your message has been sent to " <<
        @new_message.recipient.username.to_s << "."

      @new_message = Message.new
    end

    render :action => "index"
  end

  def show
    @new_message = Message.new
    @new_message.recipient_username = (@message.author_user_id == @user.id ?
      @message.recipient.username : @message.author.username)

    if @message.recipient_user_id == @user.id
      @message.has_been_read = true
      @message.save
    end

    if @message.subject.match(/^re:/i)
      @new_message.subject = @message.subject
    else
      @new_message.subject = "Re: #{@message.subject}"
    end
  end

  def destroy
    if @message.author_user_id == @user.id
      @message.deleted_by_author = true
    end
    
    if @message.recipient_user_id == @user.id
      @message.deleted_by_recipient = true
    end

    @message.save

    flash[:success] = "Deleted message."
    return redirect_to "/messages"
  end

  def keep_as_new
    @message.has_been_read = false
    @message.save

    return redirect_to "/messages"
  end

private
  def find_message
    if @message = Message.find_by_short_id(params[:message_id ] || params[:id])
      if (@message.author_user_id == @user.id ||
      @message.recipient_user_id == @user.id)
        return true
      end
    end

    flash[:error] = "Could not find message."
    redirect_to "/messages"
    return false
  end
end
