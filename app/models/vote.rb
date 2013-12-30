class Vote < ActiveRecord::Base
  belongs_to :user
  belongs_to :story

  STORY_REASONS = {
    "O" => "Off-topic",
    "Q" => "Low Quality",
    "A" => "Already Posted",
    "T" => "Poorly Tagged",
    "L" => "Poorly Titled",
    "S" => "Spam",
    "" => "Cancel",
  }

  COMMENT_REASONS = {
    "O" => "Off-topic",
    "I" => "Incorrect",
    "M" => "Me-too",
    "T" => "Troll",
    "S" => "Spam",
    "" => "Cancel",
  }

  attr_accessible nil

  def self.votes_by_user_for_stories_hash(user, stories)
    votes = {}

    Vote.where(:user_id => user, :story_id => stories,
    :comment_id => nil).each do |v|
      votes[v.story_id] = v.vote
    end

    votes
  end

  def self.comment_votes_by_user_for_story_hash(user_id, story_id)
    votes = {}

    Vote.where(
      :user_id => user_id, :story_id => story_id
    ).where(
      "comment_id IS NOT NULL"
    ).each do |v|
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

  def self.vote_thusly_on_story_or_comment_for_user_because(vote, story_id,
  comment_id, user_id, reason, update_counters = true)
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
        if !v.new_record?
          if v.vote == -1
            downvote = -1
          else
            upvote = -1
          end
        end

        v.destroy

      # new vote or change vote
      else
        if v.new_record?
          if vote == -1
            downvote = 1
          else
            upvote = 1
          end
        elsif v.vote == -1
          # changing downvote to upvote
          downvote = -1
          upvote = 1
        elsif v.vote == 1
          # changing upvote to downvote
          upvote = -1
          downvote = 1
        end

        v.vote = vote
        v.reason = reason
        v.save!
      end

      if update_counters && (downvote != 0 || upvote != 0)
        if v.comment_id
          c = Comment.find(v.comment_id)
          if c.user_id != user_id
            Keystore.increment_value_for("user:#{c.user_id}:karma",
              upvote - downvote)
          end

          c.give_upvote_or_downvote_and_recalculate_confidence!(upvote,
            downvote)
        else
          s = Story.find(v.story_id)
          if s.user_id != user_id
            Keystore.increment_value_for("user:#{s.user_id}:karma",
              upvote - downvote)
          end

          s.give_upvote_or_downvote_and_recalculate_hotness!(upvote, downvote)
        end
      end
    end
  end
end
