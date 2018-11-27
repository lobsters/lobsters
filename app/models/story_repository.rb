class StoryRepository
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
    Story.base.hidden_by(@user).filter_tags(@params[:exclude_tags] || []).order("hotness")
  end

  def newest
    Story.base.filter_tags(@params[:exclude_tags] || []).order(id: :desc)
  end

  def newest_by_user(user)
    if @user == user
      stories = Story.includes(:tags).not_deleted.left_joins(:merged_stories)
      unmerged = stories.unmerged.where(user_id: user.id)
      merged_into_others = stories.merged.where(merged_stories_stories: { user_id: user.id })

      unmerged.or(merged_into_others).order(id: :desc)
    else
      Story.base.where(user_id: user.id).order("stories.id DESC")
    end
  end

  def newest_including_deleted_by_user(user)
    Story.includes(:tags).unmerged.where(user_id: user.id).order(id: :desc)
  end

  def saved
    Story.base.saved_by(@user).filter_tags(@params[:exclude_tags] || []).order(:hotness)
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
    tagged.order(created_at: :desc)
  end

  def top(length)
    top = Story.base.where("created_at >= (NOW() - INTERVAL " <<
      "#{length[:dur]} #{length[:intv].upcase})")
    top.order("#{Story.score_sql} DESC")
  end
end
