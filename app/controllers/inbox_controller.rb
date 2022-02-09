class InboxController < ApplicationController
  before_action :require_logged_in_user

  # TODO: inbox subnav for messages/the several replies pages
  def index
    if @user.unread_replies_count > 0
      redirect_to replies_unread_path
    elsif @user.unread_message_count > 0
      redirect_to messages_path
    else
      redirect_to replies_path
    end
  end
end
