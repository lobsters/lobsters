class RepliesController < ApplicationController
  REPLIES_PER_PAGE = 25

  before_action :require_logged_in_user, :set_page
  after_action :update_read_ribbons, only: [:unread]

  def all
    @heading = @title = "All Your Replies"
    @replies = ReplyingComment
                 .for_user(@user.id)
                 .offset((@page - 1) * REPLIES_PER_PAGE)
                 .limit(REPLIES_PER_PAGE)
    apply_current_vote
    render :show
  end

  def comments
    @heading = @title = "Your Comment Replies"
    @replies = ReplyingComment
                 .comment_replies_for(@user.id)
                 .offset((@page - 1) * REPLIES_PER_PAGE)
                 .limit(REPLIES_PER_PAGE)
    apply_current_vote
    render :show
  end

  def stories
    @heading = @title = "Your Story Replies"
    @replies = ReplyingComment
                 .story_replies_for(@user.id)
                 .offset((@page - 1) * REPLIES_PER_PAGE)
                 .limit(REPLIES_PER_PAGE)
    apply_current_vote
    render :show
  end

  def unread
    @heading = @title = "Your Unread Replies"
    @replies = ReplyingComment.unread_replies_for(@user.id)
    apply_current_vote
    render :show
  end

private

  # comments/_comment expects Comment objects to have a comment_vote attribute
  # with the current user's vote added by StoriesController.load_user_votes
  def apply_current_vote
    @replies.each do |r|
      next unless r.current_vote_vote.present?
      r.comment.current_vote = {
        vote: r.current_vote_vote,
        reason: r.current_vote_reason.to_s,
      }
    end
  end

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
      .update_all(updated_at: Time.current)
  end
end
