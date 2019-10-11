module StoriesHelper
  def show_guidelines?
    if !@user
      return true
    end

    if @user.stories_submitted_count <= 5
      return true
    end

    if Moderation.joins(:story)
                 .where(
                   "stories.user_id = ? AND moderations.created_at > ?",
                   @user.id,
                   5.days.ago
                 ).exists?
      return true
    end

    false
  end

  def is_unread?(comment)
    if !@user || !@ribbon
      return false
    end

    (comment.created_at > @ribbon.updated_at) && (comment.user_id != @user.id)
  end

  def self.repost_story_description(story, story_params)
    if ActiveRecord::Type::Boolean.new.deserialize(story_params[:repost_description])
      story.description= ""
      comment = story.comments.build
      comment.comment = story_params[:description].to_s
      comment.user = User.find(story.user_id)
      comment.created_at = story.created_at
      comment.updated_at = story.created_at
      true
    else
      false
    end
  end
end
