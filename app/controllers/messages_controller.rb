# typed: false

class MessagesController < ApplicationController
  before_action :require_logged_in_user
  before_action :require_logged_in_moderator, only: [:mod_note]
  before_action :find_message, only: [:show, :destroy, :keep_as_new, :mod_note]
  before_action :show_title_h1

  def index
    @title = "Private Messages"
    @messages = Message.inbox(@user).load

    respond_to do |format|
      format.html {
        @title = "Messages"

        @new_message = Message.new

        @direction = :in

        if params[:to]
          @new_message.recipient_username = params[:to]
        end
      }
      format.json {
        render json: @messages
      }
    end
  end

  def sent
    @title = "Sent Messages"
    @messages = Message.outbox(@user).load

    respond_to do |format|
      format.html {
        @title = "Messages Sent"

        @direction = :out

        @new_message = Message.new

        render action: "index"
      }
      format.json {
        render json: @messages
      }
    end
  end

  def create
    @title = "Messages"

    @new_message = Message.new(message_params)
    @new_message.author_user_id = @user.id
    @new_message.hat = @user.wearable_hats.find_by(short_id: params[:message][:hat_id])

    @direction = :out

    if @new_message.save
      if @user.is_moderator? && @new_message.mod_note
        ModNote.create_from_message(@new_message, @user)
      end
      flash[:success] = "Your message has been sent to #{@new_message.recipient.username}."
      NotifyMessageJob.perform_later(@new_message)
      redirect_to "/messages"
    else
      @messages = Message.inbox(@user).load
      render action: "index"
    end
  end

  def show
    @title = @message.subject

    if @message.author
      @new_message = Message.new
      @new_message.recipient_username = ((@message.author_user_id == @user.id) ?
        @message.recipient.username : @message.author.username)

      @new_message.subject = if /^re:/i.match?(@message.subject)
        @message.subject
      else
        "Re: #{@message.subject}"
      end
    end

    if @message.recipient_user_id == @user.id
      @message.has_been_read = true
      @message.save!
      @message.notification&.touch(:read_at)
    end
    Rails.cache.delete("user:#{@user.id}:unread_replies")
  end

  def destroy
    if @message.author_user_id == @user.id
      @message.deleted_by_author = true
    end

    if @message.recipient_user_id == @user.id
      @message.deleted_by_recipient = true
    end

    @message.save!

    flash[:success] = "Deleted message."

    if @message.author_user_id == @user.id
      redirect_to "/messages/sent"
    else
      redirect_to "/messages"
    end
  end

  def batch_delete
    deleted = 0

    params.each do |k, v|
      if (v.to_s == "1") && (m = k.match(/^delete_(.+)$/))
        if (message = Message.where(short_id: m[1]).first)
          ok = false
          if message.author_user_id == @user.id
            message.deleted_by_author = true
            ok = true
          end
          if message.recipient_user_id == @user.id
            message.deleted_by_recipient = true
            ok = true
          end

          if ok
            message.save!
            deleted += 1
          end
        end
      end
    end

    flash[:success] = "Deleted #{deleted} #{"message".pluralize(deleted)}"

    @user.update_unread_message_count!

    redirect_to "/messages"
  end

  def keep_as_new
    @message.has_been_read = false
    @message.save!
    @message.notification&.update(read_at: nil)

    redirect_to "/messages"
  end

  def mod_note
    ModNote.create_from_message(@message, @user)

    redirect_to @message, notice: "ModNote created"
  end

  private

  def message_params
    params.require(:message).permit(
      :recipient_username, :subject, :body, :hat_id,
      @user.is_moderator? ? :mod_note : nil
    )
  end

  def find_message
    if (@message = Message.where(short_id: params[:message_id] || params[:id]).first)
      if @message.author_user_id == @user.id || @message.recipient_user_id == @user.id
        return true
      end
    end

    flash[:error] = "Could not find message."
    redirect_to "/messages"
    false
  end
end
