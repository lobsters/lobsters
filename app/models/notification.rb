class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  include Token

  GoodFaithResult = Data.define(:good_faith?, :bad_properties)

  def check_good_faith
    case notifiable
    when Message
      check_good_faith_message
    when Comment
      check_good_faith_comment
    end
  end

  def check_good_faith_message
    GoodFaithResult.new(true, {})
  end

  def check_good_faith_comment
    comment = notifiable
    story = comment.story
    parent_comment = comment.parent_comment
    replier_comment_ids = comment.user.comments.filter_map { |c| c.id if c.story_id == story.id }

    bad_properties = {
      bad_story: story.score <= story.flags,
      is_gone: comment.is_gone?,
      bad_comment: comment.score <= comment.flags,
      bad_parent_comment: parent_comment.nil? ? false : parent_comment.score <= parent_comment.flags || parent_comment.is_gone?,
      user_has_flagged_replier: !user.votes.filter { |v| v.story_id == story.id && v.vote == -1 && replier_comment_ids.include?(v.comment_id) }.empty?,
      user_has_hidden_story: !user.hidings.filter { |h| h.story_id == story.id }.empty?,
      user_has_filtered_tags_on_story: !(story.tags & user.tag_filter_tags).empty?
    }.compact_blank

    GoodFaithResult.new(bad_properties.empty?, bad_properties.keys)
  end
end
