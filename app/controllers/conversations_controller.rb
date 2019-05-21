class ConversationsController < ApplicationController
  before_action :require_logged_in_user

  def index
    @conversations = Conversation.includes(:messages).involving(@user)
  end
end
