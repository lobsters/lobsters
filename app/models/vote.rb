class Vote < ActiveRecord::Base
	belongs_to :user
  belongs_to :story

  STORY_REASONS = {
		"S" => "Spam",
		"T" => "Poorly Tagged",
		"O" => "Off-topic",
		"" => "Cancel",
  }

  COMMENT_REASONS = {
		"O" => "Off-topic",
		"I" => "Incorrect",
		"T" => "Troll",
		"S" => "Spam",
		"" => "Cancel",
	}

	def self.votes_by_user_for_stories_hash(user, stories)
    votes = []
    Vote.where(:user_id => user, :story_id => stories).each do |v|
			votes[v.story_id] = v.vote
    end

		votes
	end

	def self.comment_votes_by_user_for_story_hash(user_id, story_id)
		votes = {}

    Vote.find(:all, :conditions => [ "user_id = ? AND story_id = ? AND " +
    "comment_id IS NOT NULL", user_id, story_id ]).each do |v|
			votes[v.comment_id] = cv.vote
    end

    votes
  end

	def self.vote_thusly_on_story_or_comment_for_user_because(vote, story_id,
  comment_id, user_id, reason)
    v = if story_id
      Vote.find_or_initialize_by_user_id_and_story_id(user_id, story_id)
    elsif comment_id
      Vote.find_or_initialize_by_user_id_and_comment_id(user_id, comment_id)
    end

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
          if v.vote == -1
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

      if downvote != 0 || upvote != 0
        if v.story_id
          Story.update_counters v.story_id, :downvotes => downvote,
            :upvotes => upvote
        elsif v.comment_id
          Comment.update_counters v.comment_id, :downvotes => downvote,
            :upvotes => upvote
        end
      end
    end
  end
end
