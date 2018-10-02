module UsersHelper
  def stories_submitted(showing_user)
    tag = showing_user.most_common_story_tag

    capture do
      concat link_to(showing_user.stories_submitted_count, "/newest/#{showing_user.username}")

      if tag
        concat ", "
        concat "most commonly tagged "
        concat link_to(tag.tag, tag_path(tag), class: tag.css_class, title: tag.description)
      end
    end
  end
end
