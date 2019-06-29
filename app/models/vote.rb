class Vote < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :story, optional: false
  belongs_to :comment, optional: true

  COMMENT_REASONS = {
    "O" => "Off-topic",
    "I" => "Incorrect",
    "M" => "Me-too",
    "T" => "Troll",
    "S" => "Spam",
    "" => "Cancel",
  }.freeze

  STORY_REASONS = {
    "O" => "Off-topic",
    "A" => "Already Posted",
    "S" => "Spam",
    "B" => "Broken Link",
    "" => "Cancel",
  }.freeze
  OLD_STORY_REASONS = {
    "Q" => "Low Quality",
  }.freeze

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
    vote, story_id, comment_id, user_id, reason, update_counters = true
  )
    v = Vote.where(:user_id => user_id, :story_id => story_id,
      :comment_id => comment_id).first_or_initialize

    # vote is already recorded, return
    return if !v.new_record? && v.vote == vote

    #  v.vote  vote  up  down
    #  -1       1     1   -1
    #   0       1     1    0
    #  -1       0     0   -1
    #   1       0    -1    0
    #   0      -1     0    1
    #   1      -1    -1    1
    if vote == 1
      upvote = 1
    elsif v.vote == 1
      upvote = -1
    else
      upvote = 0
    end
    if vote == -1
      downvote = 1
    elsif v.vote == -1
      downvote = -1
    else
      downvote = 0
    end

    if vote == 0
      v.destroy!
    else
      v.vote = vote
      v.reason = reason
      v.save!
    end

    if update_counters
      t = v.target
      if v.user_id != t.user_id
        User.update_counters t.user_id, karma: upvote - downvote
      end
      t.give_upvote_or_downvote_and_recalculate!(upvote, downvote)
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
