module StoriesHelper
  def show_guidelines?
    if !@user
      return true
    end

    if @user.stories_submitted_count <= 5
      return true
    end

    if Moderation.joins(:story).
    where("stories.user_id = ? AND moderations.created_at > ?", @user.id,
    5.days.ago).count > 0
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
end
