class Api::V1::MessagesController < Api::V1::BaseController
  skip_before_action :doorkeeper_authorize!
  before_action -> { doorkeeper_authorize! :readmessages }

  def index
    @messages = current_user.undeleted_received_messages
    render :json => @messages
  end
end
