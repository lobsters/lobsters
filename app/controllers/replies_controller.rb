class RepliesController < ApplicationController
  REPLIES_PER_PAGE = 25

  before_action :require_logged_in_user_or_400, :set_page
  after_action :update_read_ribbons, only: [ :unread ]

  def all
    @heading = @title = "All Your Replies"
    @replies = ReplyingComment
                 .for_user(@user.id)
                 .offset((@page - 1) * REPLIES_PER_PAGE)
                 .limit(REPLIES_PER_PAGE)
    render :show
  end

  def comments
    @heading = @title = "Your Comment Replies"
    @replies = ReplyingComment
                 .comment_replies_for(@user.id)
                 .offset((@page - 1) * REPLIES_PER_PAGE)
                 .limit(REPLIES_PER_PAGE)
    render :show
  end

  def stories
    @heading = @title = "Your Story Replies"
    @replies = ReplyingComment
                 .story_replies_for(@user.id)
                 .offset((@page - 1) * REPLIES_PER_PAGE)
                 .limit(REPLIES_PER_PAGE)
    render :show
  end

  def unread
    @heading = @title = "Your Unread Replies"
    @replies = ReplyingComment.unread_replies_for(@user.id)
    render :show
  end

  private

  def set_page
    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2 ** 32)
      raise ActionController::RoutingError.new("page out of bounds")
    end
  end

  def update_read_ribbons
    story_ids = @replies.pluck(:story_id).uniq
    ReadRibbon
      .where(user_id: @user.id, story_id: story_ids)
      .update_all(updated_at: Time.now)
  end
end
