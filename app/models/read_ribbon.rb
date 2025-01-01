# typed: false

class ReadRibbon < ApplicationRecord
  belongs_to :user
  belongs_to :story

  validates :is_following, inclusion: {in: [true, false]}

  def is_unread? comment
    return false if !user || new_record?

    (comment.created_at > updated_at) && (comment.user_id != user.id)
  end

  # I mostly extracted this method so there's an easy seam for /s/fieikd
  # For perf the count needs to get pushed up to fetching the list of stories.
  def unread_count comments
    @unread_count ||= comments.count { |c| is_unread?(c) }
  end

  # don't add callbacks to this model; for performance the read tracking in
  # StoriesController uses .bump and RepliesController uses update_all, etc.

  def self.expire_old_ribbons!
    where("updated_at < ?", 1.year.ago).delete_all
  end

  def self.hide_replies_for(story_id, user_id)
    if (ribbon = find_by(user_id: user_id, story_id: story_id))
      ribbon.is_following = false
      ribbon.save!
    end
  end

  def self.unhide_replies_for(story_id, user_id)
    if (ribbon = find_by(user_id: user_id, story_id: story_id))
      ribbon.is_following = true
      ribbon.save!
    end
  end

  # save without callbacks, validation, or transaction
  def bump
    if new_record?
      save!
    else
      update_column(:updated_at, Time.now.utc)
    end
  end
end
