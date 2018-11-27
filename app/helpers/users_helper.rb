module UsersHelper
  def stories_submitted_content(showing_user)
    tag = showing_user.most_common_story_tag

    stories_submitted = showing_user.stories_submitted_count
    stories_deleted = showing_user.stories_deleted_count
    stories_displayed = stories_submitted - stories_deleted

    capture do
      concat link_to(stories_displayed, "/newest/#{showing_user.username}")

      concat(" (+#{stories_deleted} deleted)") if user_is_moderator? && stories_deleted > 0

      if tag
        concat ", most commonly tagged "
        concat link_to(tag.tag, tag_path(tag), class: tag.css_class, title: tag.description)
      end
    end
  end

  def comments_posted_content(showing_user)
    comments_deleted = showing_user.comments_deleted_count

    capture do
      concat link_to(showing_user.comments_posted_count, "/threads/#{showing_user.username}")

      if user_is_moderator? && comments_deleted > 0
        concat " (+#{comments_deleted} deleted)"
      end
    end
  end

private

  def user_is_moderator?
    @user && @user.is_moderator?
  end
end
