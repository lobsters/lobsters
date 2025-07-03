class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  include Token

  def good?
    case notifiable
    when Message
      good_message?
    when Comment
      good_comment?
    end
  end

  def good_message?
    true
  end

  def good_comment?
    comment = notifiable
    story = comment.story
    parent_comment = comment.parent_comment

    good_story = story.score > story.flags
    good_comment = comment.score > comment.flags && !comment.is_gone?
    good_parent_comment = parent_comment.nil? ? true : parent_comment.score > parent_comment.flags && !parent_comment.is_gone?
    user_has_flagged_replier = Vote.joins(:comment).where(user: user, story: story, vote: -1, comment: {user: comment.user}).any?
    user_has_hidden_story = HiddenStory.where(user: user, story: story).any?
    filtered_tags = story.tags & user.tag_filter_tags

    good_story && good_comment && good_parent_comment && !user_has_flagged_replier && !user_has_hidden_story && filtered_tags.empty?
  end
end
