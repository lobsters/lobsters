class CommentVoteHydrator
  def initialize(comments, user)
    @comments = comments
    @user = user
  end

  def get
    hydrate
  end

  private

  def hydrate
    return @comments unless @user && @comments.any?

    comment_ids = @comments.map(&:id)
    votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, comment_ids)
    vote_summaries = Vote.comment_vote_summaries(comment_ids)
    current_user_reply_parents = @user.ids_replied_to(comment_ids)

    @comments.each do |c|
      c.current_vote = votes[c.id]
      c.vote_summary = vote_summaries[c.id]
      c.current_reply = current_user_reply_parents.has_key? c.id
    end
    @comments
  end
end
