class Vote < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :story, optional: false
  belongs_to :comment, optional: true

  validates :vote, presence: true
  validates :reason,
            length: { is: 1 },
            allow_blank: true

  # don't forget to edit the explanations on /about
  COMMENT_REASONS = {
    "O" => "Off-topic",
    "M" => "Me-too",
    "T" => "Troll",
    "U" => "Unkind",
    "S" => "Spam",
    "" => "Cancel",
  }.freeze
  ALL_COMMENT_REASONS = COMMENT_REASONS.merge({
    "I" => "Incorrect",
  }).freeze

  # don't forget to edit the explanations on /about
  STORY_REASONS = {
    "O" => "Off-topic",
    "A" => "Already Posted",
    "B" => "Broken Link",
    "S" => "Spam",
    "" => "Cancel",
  }.freeze
  ALL_STORY_REASONS = STORY_REASONS.merge({
    "Q" => "Low Quality",
  }).freeze

  def self.votes_by_user_for_stories_hash(user, stories)
    votes = {}

    Vote.where(:user_id => user, :story_id => stories,
    :comment_id => nil).find_each do |v|
      votes[v.story_id] = { :vote => v.vote, :reason => v.reason }
    end

    votes
  end

  def self.comment_votes_by_user_for_story_hash(user_id, story_id)
    votes = {}

    Vote.where(
      :user_id => user_id, :story_id => story_id
    ).where(
      "comment_id IS NOT NULL"
    ).find_each do |v|
      votes[v.comment_id] = { :vote => v.vote, :reason => v.reason }
    end

    votes
  end

  def self.story_votes_by_user_for_story_ids_hash(user_id, story_ids)
    if story_ids.empty?
      {}
    else
      votes = self.where(
        :user_id    => user_id,
        :comment_id => nil,
        :story_id   => story_ids,
      )
      votes.inject({}) do |memo, v|
        memo[v.story_id] = { :vote => v.vote, :reason => v.reason }
        memo
      end
    end
  end

  def self.comment_votes_by_user_for_comment_ids_hash(user_id, comment_ids)
    if comment_ids.empty?
      {}
    else
      votes = self.where(
        :user_id    => user_id,
        :comment_id => comment_ids,
      )
      votes.inject({}) do |memo, v|
        memo[v.comment_id] = { :vote => v.vote, :reason => v.reason }
        memo
      end
    end
  end

  def self.vote_thusly_on_story_or_comment_for_user_because(
    new_vote, story_id, comment_id, user_id, reason, update_counters = true
  )
    v = Vote.where(:user_id => user_id, :story_id => story_id,
      :comment_id => comment_id).first_or_initialize

    return if !v.new_record? && v.vote == new_vote # done if there's no change

    score_delta = new_vote - v.vote.to_i
    if v.vote == -1
      # we know there's a change, so we must be removing a flag
      flag_delta = -1
    elsif new_vote == -1
      # we know there's a change, so we must be adding a flag
      flag_delta = 1
    else
      # change from 1 to 0 or 0 to 1, so number of flags doesn't change
      flag_delta = 0
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
    if self.comment_id
      Comment.find(self.comment_id)
    else
      Story.find(self.story_id)
    end
  end
end
