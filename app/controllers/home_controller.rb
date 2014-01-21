class HomeController < ApplicationController
  STORIES_PER_PAGE = 25

  # for rss feeds, load the user's tag filters if a token is passed
  before_filter :find_user_from_rss_token, :only => [ :index, :newest ]

  def index
    @stories = find_stories_for_user_and_tag_and_newest_and_by_user(@user,
      nil, false, nil)

    @rss_link ||= "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0\" href=\"/rss" <<
      (@user ? "?token=#{@user.rss_token}" : "") << "\" />"

    @heading = @title = ""
    @cur_url = "/"

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        if @user && params[:token].present?
          @title = "Private feed for #{@user.username}"
        end

        render :action => "rss", :layout => false
      }
      format.json { render :json => @stories }
    end
  end

  def newest
    @stories = find_stories_for_user_and_tag_and_newest_and_by_user(@user,
      nil, true, nil)

    @heading = @title = "Newest Stories"
    @cur_url = "/newest"

    @rss_link = "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0 - Newest Items\" href=\"/newest.rss" <<
      (@user ? "?token=#{@user.rss_token}" : "") << "\" />"

    @newest = true

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        if @user && params[:token].present?
          @title += " - Private feed for #{@user.username}"
        end

        render :action => "rss", :layout => false
      }
      format.json { render :json => @stories }
    end
  end

  def newest_by_user
    for_user = User.where(:username => params[:user]).first!

    @stories = find_stories_for_user_and_tag_and_newest_and_by_user(@user,
      nil, false, for_user.id)

    @heading = @title = "Newest Stories by #{for_user.username}"
    @cur_url = "/newest/#{for_user.username}"

    @newest = true
    @for_user = for_user.username

    render :action => "index"
  end

  def tagged
    @tag = Tag.where(:tag => params[:tag]).first!
    @stories = find_stories_for_user_and_tag_and_newest_and_by_user(@user,
      @tag, false, nil)

    @heading = @title = @tag.description.blank?? @tag.tag : @tag.description
    @cur_url = tag_url(@tag.tag)

    @rss_link = "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0 - Tagged #{CGI.escape(@tag.tag)} " <<
      "(#{CGI.escape(@tag.description.to_s)})\" href=\"/t/" +
      "#{CGI.escape(@tag.tag)}.rss\" />"

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
    end
  end

  def privacy
    begin
      render :action => "privacy"
    rescue
      render :text => "<div class=\"box wide\">" <<
        "You apparently have no privacy." <<
        "</div>", :layout => "application"
    end
  end

  def about
    begin
      render :action => "about"
    rescue
      render :text => "<div class=\"box wide\">" <<
        "A mystery." <<
        "</div>", :layout => "application"
    end
  end

private
  def find_stories_for_user_and_tag_and_newest_and_by_user(user, tag = nil,
  newest = false, by_user = nil)
    # guest views have caching, but don't bother for logged-in users or dev or
    # when the user has tag filters
    if Rails.env == "development" || user || tags_filtered_by_cookie.any?
      _find_stories_for_user_and_tag_and_newest_and_by_user(user, tag,
        newest, by_user)
    else
      cache(request.fullpath, :expires_in => 45) do
        _find_stories_for_user_and_tag_and_newest_and_by_user(user, tag,
          newest, by_user)
      end
    end
  end

  def _find_stories_for_user_and_tag_and_newest_and_by_user(user, tag = nil,
  newest = false, by_user = nil)
    stories = Story.where(:is_expired => false)

    if user && !(newest || by_user)
      # exclude downvoted items
      stories = stories.where(
        Story.arel_table[:id].not_in(
          Vote.arel_table.where(
            Vote.arel_table[:user_id].eq(user.id)
          ).where(
            Vote.arel_table[:vote].lt(0)
          ).where(
            Vote.arel_table[:comment_id].eq(nil)
          ).project(
            Vote.arel_table[:story_id]
          )
        )
      )
    end

    filtered_tag_ids = []
    if user
      filtered_tag_ids = @user.tag_filters.map{|tf| tf.tag_id }
    else
      filtered_tag_ids = tags_filtered_by_cookie.map{|t| t.id }
    end

    if tag
      stories = stories.where(
        Story.arel_table[:id].in(
          Tagging.arel_table.where(
            Tagging.arel_table[:tag_id].eq(tag.id)
          ).project(
            Tagging.arel_table[:story_id]
          )
        )
      )
    elsif by_user
      stories = stories.where(:user_id => by_user)
    elsif filtered_tag_ids.any?
      stories = stories.where(
        Story.arel_table[:id].not_in(
          Tagging.arel_table.where(
            Tagging.arel_table[:tag_id].in(filtered_tag_ids)
          ).project(
            Tagging.arel_table[:story_id]
          )
        )
      )
    end

    stories = stories.includes(
      :user, :taggings => :tag
    ).order(
      newest ? "stories.created_at DESC" : "hotness"
    )

    story_count = stories.count

    stories = stories.page(
      params[:page]
    ).per(
      STORIES_PER_PAGE
    ).to_a

    # TODO: figure out a better sorting algorithm for newest, including some
    # older stories that got one or two votes

    if user
      votes = Vote.votes_by_user_for_stories_hash(user.id,
        stories.map{|s| s.id })

      stories.each do |s|
        if votes[s.id]
          s.vote = votes[s.id]
        end
      end
    end

    Kaminari.paginate_array(
      stories, :total_count => story_count
    ).page(
      params[:page]
    ).per(
      STORIES_PER_PAGE
    )
  end
end
