class RepliesController < ApplicationController
  REPLIES_PER_PAGE = 25
  
  before_action :require_logged_in_user_or_400
  after_action :update_read_ribbons
                
  def show
    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2 ** 32)
      raise ActionController::RoutingError.new("page out of bounds")
    end

    @filter = params[:filter] || 'unread'
    
    case @filter
    when 'comments'
      @heading = @title = I18n.t('controllers.replies_controller.commentstitle')
      @replies = ReplyingComment
                   .comment_replies_for(@user.id)
                   .offset((@page - 1) * REPLIES_PER_PAGE)
                   .limit(REPLIES_PER_PAGE)
    when 'stories'
      @heading = @title = I18n.t('controllers.replies_controller.storiestitle')
      @replies = ReplyingComment
                   .story_replies_for(@user.id)
                   .offset((@page - 1) * REPLIES_PER_PAGE)
                   .limit(REPLIES_PER_PAGE)
    when 'all'
      @heading = @title = I18n.t('controllers.replies_controller.alltitle')
      @replies = ReplyingComment
                   .for_user(@user.id)
                   .offset((@page - 1) * REPLIES_PER_PAGE)
                   .limit(REPLIES_PER_PAGE)
    else
      @heading = @title = I18n.t('controllers.replies_controller.unreadtitle')
      @replies = ReplyingComment.unread_replies_for(@user.id)
    end
  end

  private

  def update_read_ribbons
    return unless @filter == 'unread'
    stories = @replies.pluck(:story_id).uniq

    stories.each do |story|
      ribbon = ReadRibbon.find_by(user_id: @user.id, story_id: story)
      ribbon.updated_at = Time.now
      ribbon.save!
    end
  end
end
