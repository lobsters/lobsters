module UsersHelper
  def stories_submitted_content(showing_user)
    tag = showing_user.most_common_story_tag

    stories_submitted = showing_user.stories_submitted_count
    stories_deleted = showing_user.stories_deleted_count
    stories_displayed = stories_submitted - stories_deleted

    capture do
      concat link_to(stories_displayed, newest_by_user_path(showing_user))

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
      concat link_to(showing_user.comments_posted_count, user_threads_path(showing_user))

      if user_is_moderator? && comments_deleted > 0
        concat " (+#{comments_deleted} deleted)"
      end
    end
  end

  def styled_user_link user, content = nil, css_classes = []
    if content.is_a?(Story) && content.user_is_author?
      css_classes.push 'user_is_author'
    end
    if content.is_a?(Comment) && content.story &&
       content.story.user_is_author? && content.story.user_id == user.id
      css_classes.push 'user_is_author'
    end

    if !user.is_active?
      css_classes.push 'inactive_user'
    end
    if user.is_new?
      css_classes.push 'new_user'
    end

    link_to(user.username, user, class: css_classes)
  end

  def user_karma(user)
    if user.is_admin?
      "(administrator)"
    elsif user.is_moderator?
      "(moderator"
    else
      "(#{user.karma})"
    end
  end

private

  def user_is_moderator?
    @user && @user.is_moderator?
  end
end
