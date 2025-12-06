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

  def is_youtube_url?(url)
    return false if url.blank?
    url.to_s.include?('youtube.com/watch?v=') or url.to_s.include?('youtu.be')
  end

  def extract_youtube_video_id(url)
    return nil if url.blank?
    if url.to_s.include?('youtube.com/watch?v=')
      url.to_s[/youtube\.com\/watch\?v=([A-Za-z0-9\-_]+)/, 1]
    else
      url.to_s[/youtu\.be\/([A-Za-z0-9\-_]+)/, 1]
    end
  end
end
