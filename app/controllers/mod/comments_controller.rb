class Mod::CommentsController < Mod::ModController
  after_action only: [:destroy] do
    refill_story_page_cache @comment.story, is_moderator: true
  end

  def destroy
    if !@comment = find_comment
      return render plain: "can't find comment", status: 400
    end

    reason = params[:reason]
    @comment.delete_by_moderator(@user, reason)

    if request.xhr?
      render partial: "comments/comment",
        layout: false,
        content_type: "text/html",
        locals: {comment: @comment}
    else
      redirect_to comment_path(@comment)
    end
  end

  private

  def find_comment
    comment = Comment.find_by(short_id: params[:id])
    return comment if comment.nil?

    # Load the view state the same way CommentsController#find_comment does.
    # Without it, rendering the comment partial (the XHR response of this
    # action) drops the current user's vote, so an upvoted comment comes back
    # with an empty upvote arrow until the page is reloaded (#2201).
    comment.current_vote = Vote.where(
      user_id: @user.id, story_id: comment.story_id, comment_id: comment.id
    ).first
    comment.vote_summary = Vote.comment_vote_summaries([comment.id])[comment.id]
    comment
  end
end
