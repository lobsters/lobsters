# typed: false

class Vote < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :story, optional: false
  belongs_to :comment, optional: true

  normalizes :reason, with: ->(r) { r.to_s }, apply_to_nil: true

  # for comment_vote_summaries
  attribute :count, :integer
  attribute :usernames, :string

  validates :vote, presence: true, inclusion: {in: [1, -1]}
  validates :reason,
    length: {is: 1},
    allow_blank: true,
    presence: true

  scope :comments_flags, ->(comments, user = nil) {
    q = where(comment: comments, vote: -1)
    user ? q.where(user: user) : q.all
  }

  # don't forget to edit the explanations on /about
  COMMENT_REASONS = {
    "O" => "Off-topic",
    "M" => "Me-too",
    "T" => "Troll",
    "U" => "Unkind",
    "S" => "Spam",
    "" => "Cancel"
  }.freeze
  ALL_COMMENT_REASONS = COMMENT_REASONS.merge({
    "I" => "Incorrect"
  }).freeze

  # don't forget to edit the explanations on /about
  STORY_REASONS = {
    "O" => "Off-topic",
    "A" => "Already Posted",
    "B" => "Broken Link",
    "S" => "Spam",
    "" => "Cancel"
  }.freeze
  ALL_STORY_REASONS = STORY_REASONS.merge({
    "Q" => "Low Quality"
  }).freeze

  def on_comment?
    comment_id.present?
  end

  def on_story?
    comment_id.blank?
  end

  def reason_text
    if on_story?
      ALL_STORY_REASONS[reason]
    else
      ALL_COMMENT_REASONS[reason]
    end
  end

  def self.comment_vote_summaries(comment_ids)
    Vote
      .joins(:user)
      .select("comment_id, reason, count(1) as count, group_concat(username separator ', ') as usernames")
      .where(comment_id: comment_ids)
      .where.not(reason: "")
      .group(:comment_id, :reason)
      .group_by(&:comment_id)
  end

  def self.votes_by_user_for_stories_hash(user, stories)
    votes = {}

    Vote.where(user_id: user, story_id: stories,
      comment_id: nil).find_each do |v|
      votes[v.story_id] = {vote: v.vote, reason: v.reason}
    end

    votes
  end

  def self.comment_votes_by_user_for_story_hash(user_id, story_id)
    votes = {}

    Vote.where(
      user_id: user_id, story_id: story_id
    ).where.not(comment_id: nil).find_each do |v|
      votes[v.comment_id] = {vote: v.vote, reason: v.reason}
    end

    votes
  end

  def self.story_votes_by_user_for_story_ids_hash(user_id, story_ids)
    if story_ids.empty?
      {}
    else
      votes = where(
        user_id: user_id,
        comment_id: nil,
        story_id: story_ids
      )
      votes.each_with_object({}) do |v, memo|
        memo[v.story_id] = {vote: v.vote, reason: v.reason}
      end
    end
  end

  def self.comment_votes_by_user_for_comment_ids_hash(user_id, comment_ids)
    return {} if user_id.nil? || comment_ids.empty?

    votes = where(
      user_id: user_id,
      comment_id: comment_ids
    ).select(:comment_id, :vote, :reason)
    votes.each_with_object({}) do |v, memo|
      memo[v.comment_id] = {vote: v.vote, reason: v.reason}
    end
  end

  def self.vote_thusly_on_story_or_comment_for_user_because(
    new_vote, story_id, comment_id, user_id, reason, update_counters = true
  )
    v = Vote.where(user_id: user_id, story_id: story_id,
      comment_id: comment_id).first_or_initialize

    # AR wraps a transaction around INSERTing to votes. I don't know why, but it also SELECTs the
    # associated story even though there isn't a touch: or callback on the association. This can
    # lead to a rare deadlock if someone is creating a story at the some time, because that has to
    # lock the stories table and then votes. This next line eagerly loads the associated story so
    # the SELECT doesn't happen during the transaction INSERTing to votes. Oddly, this doesn't
    # happen with associated comments.
    v.story if story_id.present?

    return if !v.new_record? && v.vote == new_vote # done if there's no change

    # score deltas when flags no longer affect scores
    # no vote  -> 1      1
    # flag -> 1          1
    # no vote  -> flag   0
    # flag -> no vote    0
    # 1  -> no vote     -1
    # 1  -> flag        -1
    score_delta = if new_vote == 1
      1
    elsif v.vote == 1
      -1
    else
      0
    end
    flag_delta = if v.vote == -1
      # we know there's a change, so we must be removing a flag
      -1
    elsif new_vote == -1
      # we know there's a change, so we must be adding a flag
      1
    else
      # change from 1 to 0 or 0 to 1, so number of flags doesn't change
      0
    end

    if new_vote == 0
      v.destroy!
    else
      v.vote = new_vote
      v.reason = reason
      v.save!
    end

    if update_counters
      t = v.target
      if v.user_id != t.user_id
        User.update_counters t.user_id, karma: score_delta
      end
      t.update_score_and_recalculate!(score_delta, flag_delta)
    end
  end

  def target
    if comment_id
      Comment.find(comment_id)
    else
      Story.find(story_id)
    end
  end
end
