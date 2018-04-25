class StoryRepository
  # how many days old a story can be to get on the bottom half of /recent
  RECENT_DAYS_OLD = 3
  # how many points a story has to have to probably get on the front page
  HOT_STORY_POINTS = 5

  def initialize(user = nil, params = {})
    @user = user
    @params = params
  end

  def hottest
    hottest = Story.base.positive_ranked.not_hidden_by(@user)
    hottest = hottest.filter_tags(@params[:exclude_tags] || [])
    hottest.order('hotness')
  end

  def hidden
    hidden = Story.base.hidden_by(@user).filter_tags(@params[:exclude_tags] || [])
    hidden.order("hotness")
  end

  def newest
    newest = Story.base.filter_tags(@params[:exclude_tags] || [])
    newest.order("stories.id DESC")
  end

  def newest_by_user(user)
    Story.base.where(user_id: user.id).order("stories.id DESC")
  end

  def recent
    stories = newest

    # try to help recently-submitted stories that didn't gain traction
    story_ids = []

    10.times do |x|
      # grab the list of stories from the past n days, shifting out popular
      # stories that did gain traction
      story_ids = stories.select(:id, :upvotes, :downvotes, :user_id)
        .where(Story.arel_table[:created_at].gt((RECENT_DAYS_OLD + x).days.ago))
        .order("stories.created_at DESC")
        .reject {|s| s.score > HOT_STORY_POINTS }

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

  def saved
    saved = Story.base.saved_by(@user).filter_tags(@params[:exclude_tags] || [])
    saved.order("hotness")
  end

  def tagged(tag)
    tagged = Story.base.positive_ranked.where(
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
    top = Story.base.where("created_at >= (NOW() - INTERVAL " <<
      "#{length[:dur]} #{length[:intv].upcase})")
    top.order("#{Story.score_sql} DESC")
  end
end
