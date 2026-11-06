# This wraps and hydrates comment threads with info for the current user to avoid looping the
# comments multiple times.

class CommentsLoopedMultipleTimes < StandardError; end

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

  def hydrate(comment)
    return nil if comment.nil?
    return comment if @user.nil?

    comment.current_vote ||= @votes[comment.id]
    comment.vote_summary ||= @vote_summaries[comment.id]
    comment.current_reply ||= @current_user_reply_parents.key?(comment.id)
    comment
  end

  def [](index)
    hydrate(@comments[index])
  end

  def each
    raise CommentsLoopedMultipleTimes if @looped
    @looped = true

    @comments.each { |c| yield hydrate(c) }
  end

  def each_thread(stories)
    raise CommentsLoopedMultipleTimes if @looped
    @looped = true

    from = 0
    stories.each do |story|
      first = @comments[from]
      size = (first&.story_id == story.id) ? first.thread_size : 0

      yield story, StoryThreadWindow.new(self, from, size)

      from += size
    end
    raise ArgumentError, "comments are not sorted by story" if from != @comments.size
  end

  # Enumerable#first would start a loop
  def first = self[0]

  class StoryThreadWindow
    include Enumerable

    attr_reader :size
    alias_method :length, :size

    def initialize(hydrator, from, size)
      @hydrator = hydrator
      @from = from
      @size = size
    end

    def [](index)
      index += @size if index.negative?
      return nil unless index.between?(0, @size - 1)
      @hydrator[@from + index]
    end

    def each
      raise CommentsLoopedMultipleTimes, "a thread can only be looped once" if @looped
      @looped = true

      @size.times do |i|
        yield self[i]
      end
    end

    def empty? = @size.zero?

    def first = self[0]
  end
end
