class Api::V1::MessagesController < Api::V1::BaseController
  skip_before_action :doorkeeper_authorize!
  before_action -> { doorkeeper_authorize! :readmessages }

  def index
    @messages = current_user.undeleted_received_messages
    render :json => @messages
  end

  def sent
    @messages = current_user.undeleted_sent_messages
    render :json => @messages
  end

  def create
    @new_message = Message.new(:subject => params[:subject], :body => params[:body], :recipient_username => params[:recipient_username])
    @new_message.author_user_id = current_user.id
    if @new_message.save
      render :json => @new_message
    end
  end

end
