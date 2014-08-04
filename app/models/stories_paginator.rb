class StoriesPaginator
  STORIES_PER_PAGE = 25

  def initialize(scope, page, user)
    @scope = scope
    @page = page
    @user = user
  end

  def get
    with_pagination_info @scope.limit(STORIES_PER_PAGE + 1)
      .offset((@page - 1) * STORIES_PER_PAGE)
      .includes(:user, :taggings => :tag)
  end

private
  def with_pagination_info(scope)
    scope = scope.to_a
    show_more = scope.count > STORIES_PER_PAGE
    scope.pop if show_more

    [cache_votes(scope), show_more]
  end

  def cache_votes(scope)
    if @user
      votes = Vote.votes_by_user_for_stories_hash(@user.id, scope.map(&:id))

      scope.each do |s|
        if votes[s.id]
          s.vote = votes[s.id]
        end
      end
    end
    scope
  end
end
