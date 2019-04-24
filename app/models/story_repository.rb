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
    Story.base.where(user_id: user.id).order(id: :desc)
  end

  def newest_including_deleted_by_user(user)
    Story.includes(:tags).unmerged.where(user_id: user.id).order(id: :desc)
  end

  def saved
    Story.base.saved_by(@user).filter_tags(@params[:exclude_tags] || []).order(:hotness)
  end

  def tagged(tags)
    tagged = Story.base.positive_ranked.joins(:taggings).where(taggings: { tag_id: tags.map(&:id) })

    tagged.order(created_at: :desc)
  end

  def top(length)
    top = Story.base.where("created_at >= (NOW() - INTERVAL " <<
      "#{length[:dur]} #{length[:intv].upcase})")
    top.order("#{Story.score_sql} DESC")
  end
end
