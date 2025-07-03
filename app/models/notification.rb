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
    bad_properties_to_check << [:user_has_flagged_replier, Vote.joins(:comment).where(user: user, story: story, vote: -1, comment: {user: comment.user}).any?]
    bad_properties_to_check << [:user_has_hidden_story, HiddenStory.where(user: user, story: story).any?]
    bad_properties_to_check << [:user_has_filtered_tags_on_story, !(story.tags & user.tag_filter_tags).empty?]

    bad_properties = bad_properties_to_check.filter_map { |reason, flag| flag && reason }

    GoodFaithResult.new(bad_properties.empty?, bad_properties)
  end
end
