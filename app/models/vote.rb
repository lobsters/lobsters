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

  def self.map_by(&block)
    self.all.to_a.inject({}) do |votes, vote|
      votes[ block.call vote ] = vote
      votes
    end
  end

  def self.votes_by_user_for_stories_hash(user, stories)
    self.where(
      :user_id    => user,
      :story_id   => stories,
      :comment_id => nil,
    ).map_by(&:story_id)
  end

  def self.comment_votes_by_user_for_story_hash(user_id, story_id)
    self.where(
      :user_id  => user_id,
      :story_id => story_id,
    ).where(
      "comment_id IS NOT NULL"
    ).map_by(&:comment_id)
  end

  def self.story_votes_by_user_for_story_ids_hash(user_id, story_ids)
    self.where(
      :user_id    => user_id,
      :story_id   => story_ids,
      :comment_id => nil,
    ).map_by(&:story_id)
  end

  def self.comment_votes_by_user_for_comment_ids_hash(user_id, comment_ids)
    self.where(
      :user_id    => user_id,
      :comment_id => comment_ids,
    ).map_by(&:comment_id)
  end

  def self.vote_thusly_on_story_or_comment_for_user_because(vote, story,
  comment, user_id, reason, update_counters = true)
    v = self.where(:user_id => user_id, :story_id => story.try(:id),
      :comment_id => comment.try(:id)).first_or_initialize

    if !v.new_record? && v.vote == vote
      return v
    end

    upvote = 0
    downvote = 0

    self.transaction do
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
          if comment.user_id != user_id
            User.update_counters comment.user_id, :karma => upvote - downvote
          end

          comment.give_upvote_or_downvote_and_recalculate_confidence!(upvote,
            downvote)
        else
          if story.user_id != user_id
            User.update_counters story.user_id, :karma => upvote - downvote
          end

          story.give_upvote_or_downvote_and_recalculate_hotness!(
            upvote, downvote)
        end
      end
    end

    return v unless v.destroyed?
  end
end
