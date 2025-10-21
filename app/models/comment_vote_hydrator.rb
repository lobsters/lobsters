class CommentVoteHydrator
  def initialize(comments, user)
    @comments = comments
    @comment_ids = comments.map(&:id)
    @user = user
    @hydrated = false
  end

  def [](comment)
    hydrate unless @hydrated
    comment.instance_variable_set(:@current_vote, @votes&.dig(comment.id))
    comment.instance_variable_set(:@vote_summary, @vote_summaries&.dig(comment.id))
    comment.instance_variable_set(:@current_reply, @current_user_reply_parents&.key?(comment.id) || false)
    comment
  end

  private

  def hydrate
    return unless @user && @comment_ids.any?

    @votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, @comment_ids)
    @vote_summaries = Vote.comment_vote_summaries(@comment_ids)
    @current_user_reply_parents = @user.ids_replied_to(@comment_ids)
    @hydrated = true
  end
end
