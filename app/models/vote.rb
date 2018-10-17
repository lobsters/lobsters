class Vote < ApplicationRecord
  belongs_to :user, required: false
  belongs_to :story, required: false
  belongs_to :comment, required: false

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

    if !v.new_record? && v.vote == vote
      return
    end

    upvote = 0
    downvote = 0

    Vote.transaction do
      # unvote
      if vote == 0
        # neutralize previous vote
        upvote = (v.vote == 1 ? -1 : 0)
        downvote = (v.vote == -1 ? -1 : 0)
        v.destroy!

      # new vote or change vote
      else
        if !v.new_record?
          upvote = (v.vote == 1 ? -1 : 0)
          downvote = (v.vote == -1 ? -1 : 0)
        end

        upvote += (vote == 1 ? 1 : 0)
        downvote += (vote == -1 ? 1 : 0)

        v.vote = vote
        v.reason = reason
        v.save!
      end

      if update_counters && (downvote != 0 || upvote != 0)
        if v.comment_id
          c = Comment.find(v.comment_id)
          if c.user_id != user_id
            User.update_counters c.user_id, :karma => upvote - downvote
          end

          c.give_upvote_or_downvote_and_recalculate_confidence!(upvote, downvote)
        else
          s = Story.find(v.story_id)
          if s.user_id != user_id
            User.update_counters s.user_id, :karma => upvote - downvote
          end

          s.give_upvote_or_downvote_and_recalculate_hotness!(upvote, downvote)
        end
      end
    end
  end
end
