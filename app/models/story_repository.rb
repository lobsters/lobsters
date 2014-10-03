class StoryRepository
  # how many days old a story can be to get on the bottom half of /recent
  RECENT_DAYS_OLD = 3
  # how many points a story has to have to probably get on the front page
  HOT_STORY_POINTS = 5

  def initialize(user, params = {})
    @user = user
    @params = params
  end

  def hottest
    hottest = positive_ranked base_scope
    hottest = filter_downvoted_and_tags hottest
    hottest.order('hotness')
  end

  def hidden
    hidden = base_scope
    if @user
      hidden = hidden.where(Story.arel_table[:id].in(hidden_arel))
    end
    if @params[:exclude_tags].try(:any?)
      hidden = filter_tags hidden, @params[:exclude_tags]
    end
    hidden.order("hotness")
  end

  def newest
    newest = filter_downvoted_and_tags base_scope
    newest.order("stories.id DESC")
  end

  def newest_by_user(user)
    base_scope.where(user_id: user.id).order("stories.id DESC")
  end

  def recent
    stories = newest

    # try to help recently-submitted stories that didn't gain traction
    story_ids = []

    10.times do |x|
      # grab the list of stories from the past n days, shifting out popular
      # stories that did gain traction
      story_ids = stories.select(:id, :upvotes, :downvotes, :user_id).
        where(Story.arel_table[:created_at].gt((RECENT_DAYS_OLD + x).days.ago)).
        order("stories.created_at DESC").
        reject{|s| s.score > HOT_STORY_POINTS }

      if story_ids.length > StoriesPaginator::STORIES_PER_PAGE + 1
        # keep the top half (newest stories)
        keep_ids = story_ids[0 .. ((StoriesPaginator::STORIES_PER_PAGE + 1) *
          0.5)]
        story_ids = story_ids[keep_ids.length - 1 ... story_ids.length]

        # make the bottom half a random selection of older stories
        while keep_ids.length <= StoriesPaginator::STORIES_PER_PAGE + 1
          story_ids.shuffle!
          keep_ids.push story_ids.shift
        end

        stories = Story.where(:id => keep_ids)
        break
      end
    end

    stories.order("stories.created_at DESC")
  end

  def tagged(tag)
    tagged = positive_ranked base_scope
    tagged = tagged.where(
      Story.arel_table[:id].in(
        Tagging.arel_table.where(
          Tagging.arel_table[:tag_id].eq(tag.id)
        ).project(
          Tagging.arel_table[:story_id]
        )
      )
    )
    tagged.order("stories.created_at DESC")
  end

  def top(length)
    top = base_scope.where("created_at >= (NOW() - INTERVAL " <<
      "#{length[:dur]} #{length[:intv].upcase})")
    top.order("(CAST(upvotes AS #{Story.votes_cast_type}) - " <<
      "CAST(downvotes AS #{Story.votes_cast_type})) DESC")
  end

private
  def base_scope
    Story.unmerged.where(is_expired: false)
  end

  def filter_downvoted_and_tags(scope)
    if @user
      scope = filter_downvoted scope
    end
    if @params[:exclude_tags].try(:any?)
      scope = filter_tags scope, @params[:exclude_tags]
    end
    scope
  end

  def filter_downvoted(scope)
    scope.where(Story.arel_table[:id].not_in(hidden_arel))
  end

  def hidden_arel
    if @user
      hidden_arel = Vote.arel_table.where(
        Vote.arel_table[:user_id].eq(@user.id)
      ).where(
        Vote.arel_table[:vote].lteq(0)
      ).where(
        Vote.arel_table[:comment_id].eq(nil)
      ).project(
        Vote.arel_table[:story_id]
      )
    end
  end

  def positive_ranked(scope)
    scope.where("(CAST(upvotes AS #{Story.votes_cast_type}) - " <<
      "CAST(downvotes AS #{Story.votes_cast_type})) >= -1")
  end

  def filter_tags(scope, tags)
    scope.where(
      Story.arel_table[:id].not_in(
        Tagging.arel_table.where(
          Tagging.arel_table[:tag_id].in(tags)
        ).project(
          Tagging.arel_table[:story_id]
        )
      )
    )
  end
end
