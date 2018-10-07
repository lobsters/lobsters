module UsersHelper
  def stories_submitted(showing_user)
    tag = showing_user.most_common_story_tag

    stories_submitted = showing_user.stories_submitted_count
    stories_deleted = showing_user.stories_deleted_count
    stories_displayed = @user&.is_moderator? ? stories_submitted - stories_deleted : stories_submitted

    capture do
      concat link_to(stories_displayed, "/newest/#{showing_user.username}")

      if @user&.is_moderator?
        concat " (+#{stories_deleted} deleted)"
      end

      if tag
        concat ", most commonly tagged "
        concat link_to(tag.tag, tag_path(tag), class: tag.css_class, title: tag.description)
      end
    end
  end
end
