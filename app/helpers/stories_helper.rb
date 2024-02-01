# typed: false

module StoriesHelper
  def show_guidelines?(user)
    if !user
      return true
    end

    if user.stories_submitted_count <= 5
      return true
    end

    if Moderation.joins(:story)
        .where(
          "stories.user_id = ? AND moderations.created_at > ?",
          user.id,
          5.days.ago
        ).exists?
      return true
    end

    false
  end
end
