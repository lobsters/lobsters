class Api::V1::CommentsController < Api::V1::BaseController
  skip_before_action :doorkeeper_authorize!
  before_action -> { doorkeeper_authorize! :comments }

  def create
    @story = Story.where(:short_id => params[:story_id]).first
    @comment = @story.comments.build
    @comment.comment = params[:comment].to_s
    @comment.user = current_user
    if @comment.valid? && @comment.save
      render :json => @comment
    end
  end

end
