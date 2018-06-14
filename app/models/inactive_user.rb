module InactiveUser
  def self.inactive_user
    @inactive_user ||= User.find_by!(username: 'inactive-user')
  end

  def self.disown! comment
    author = comment.user
    comment.update_column(:user_id, inactive_user.id)
    refresh_comment_counts! author
  end

  def self.disown_all_by_author! author
    author.comments.update_all(:user_id => inactive_user.id)
    refresh_comment_counts! author
  end

  def self.refresh_comment_counts! user
    user.update_comments_posted_count! if user
    inactive_user.update_comments_posted_count!
  end
end
