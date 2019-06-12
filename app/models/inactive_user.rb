module InactiveUser
  def self.inactive_user
    @inactive_user ||= User.find_by!(username: 'inactive-user')
  end

  def self.disown! comment_or_story
    author = comment_or_story.user
    comment_or_story.update_column(:user_id, inactive_user.id)
    refresh_counts! author
  end

  def self.disown_all_by_author! author
    author.stories.update_all(:user_id => inactive_user.id)
    author.comments.update_all(:user_id => inactive_user.id)
    refresh_counts! author
  end

  def self.refresh_counts! user
    user.refresh_counts! if user
    inactive_user.refresh_counts!
  end
end
