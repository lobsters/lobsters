class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  include Token

  GoodFaithResult = Struct.new(:good_faith?, :bad_properties)

  def check_good_faith
    case notifiable
    when Message
      check_good_faith_message
    when Comment
      check_good_faith_comment
    end
  end

  def check_good_faith_message
    GoodFaithResult.new(true, [])
  end

  def check_good_faith_comment
    comment = notifiable
    story = comment.story
    parent_comment = comment.parent_comment

    bad_properties_to_check = []

    bad_properties_to_check << [:bad_story, story.score <= story.flags]
    bad_properties_to_check << [:bad_comment, comment.score <= comment.flags || comment.is_gone?]
    bad_properties_to_check << [:bad_parent_comment, parent_comment.nil? ? false : parent_comment.score <= parent_comment.flags || parent_comment.is_gone?]
    replier_comment_ids = comment.user.comments.filter_map { |c| (c.story_id == story.id) ? c.id : nil }
    bad_properties_to_check << [:user_has_flagged_replier, !user.votes.filter { |v| v.story_id == story.id && v.vote == -1 && replier_comment_ids.include?(v.comment_id) }.empty?]
    bad_properties_to_check << [:user_has_hidden_story, !user.hidings.filter { |h| h.story_id == story.id }.empty?]
    bad_properties_to_check << [:user_has_filtered_tags_on_story, !(story.tags & user.tag_filter_tags).empty?]

    bad_properties = bad_properties_to_check.filter_map { |reason, flag| flag && reason }

    GoodFaithResult.new(bad_properties.empty?, bad_properties)
  end
end
