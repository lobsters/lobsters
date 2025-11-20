class CommentVoteHydrator
  include Enumerable

  delegate :size, :length, :empty?, :any?, to: :@comments

  def initialize(comments, user)
    @comments = comments
    @user = user
    if @user.nil? || comments.empty?
      @votes = {}
      @vote_summaries = {}
      @current_user_reply_parents = {}
    else
      comment_ids = comments.map(&:id)
      @votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, comment_ids)
      @vote_summaries = Vote.comment_vote_summaries(comment_ids)
      @current_user_reply_parents = @user.ids_replied_to(comment_ids)
    end
  end

  def each
    @comments.each { |c| yield self[c] }
  end

  private

  def [](comment)
    comment.current_vote ||= @votes[comment.id]
    comment.vote_summary ||= @vote_summaries[comment.id]
    comment.current_reply ||= @current_user_reply_parents.key?(comment.id)
    comment
  end
end
