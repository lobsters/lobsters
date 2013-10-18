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
    for_user = User.find_by_username!(params[:user])

    @stories = find_stories_for_user_and_tag_and_newest_and_by_user(@user,
      nil, false, for_user.id)

    @heading = @title = "Newest Stories by #{for_user.username}"
    @cur_url = "/newest/#{for_user.username}"

    @newest = true
    @for_user = for_user.username

    render :action => "index"
  end

  def tagged
    @tag = Tag.find_by_tag!(params[:tag])
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
    @page = 1
    if params[:page].to_i > 0
      @page = params[:page].to_i
    end

    # guest views have caching, but don't bother for logged-in users or dev or
    # when the user has tag filters
    if Rails.env == "development" || user || tags_filtered_by_cookie.any?
      stories, @show_more =
        _find_stories_for_user_and_tag_and_newest_and_by_user(user, tag,
        newest, by_user)
    else
      stories, @show_more = Rails.cache.fetch("stories tag:" <<
      "#{tag ? tag.tag : ""} new:#{newest} page:#{@page.to_i} by:#{by_user}",
      :expires_in => 45) do
        _find_stories_for_user_and_tag_and_newest_and_by_user(user, tag,
          newest, by_user)
      end
    end

    stories
  end

  def _find_stories_for_user_and_tag_and_newest_and_by_user(user, tag = nil,
  newest = false, by_user = nil)
    conds = [ "is_expired = 0 " ]

    if user && !(newest || by_user)
      # exclude downvoted items
      conds[0] << "AND stories.id NOT IN (SELECT story_id FROM votes " <<
        "WHERE user_id = ? AND vote < 0 AND comment_id IS NULL) "
      conds.push user.id
    end

    filtered_tag_ids = []
    if user
      filtered_tag_ids = @user.tag_filters.map{|tf| tf.tag_id }
    else
      # for logged-out users, filter defaults
      filtered_tag_ids = Tag.where(:filtered_by_default => true).
        map{|t| t.id } + tags_filtered_by_cookie.map{|t| t.id }
    end

    if tag
      conds[0] << "AND stories.id IN (SELECT taggings.story_id FROM " <<
        "taggings WHERE taggings.tag_id = ?)"
      conds.push tag.id
    elsif by_user
      conds[0] << "AND stories.user_id = ?"
      conds.push by_user
    elsif filtered_tag_ids.any?
      conds[0] += " AND stories.id NOT IN (SELECT taggings.story_id " <<
        "FROM taggings WHERE taggings.tag_id IN (" <<
        filtered_tag_ids.map{|t| "?" }.join(",") << "))"
      conds += filtered_tag_ids
    end

    stories = Story.find(
      :all,
      :conditions => conds,
      :include => [ :user, { :taggings => :tag } ],
      :limit => STORIES_PER_PAGE + 1,
      :offset => ((@page - 1) * STORIES_PER_PAGE),
      :order => (newest ? "stories.created_at DESC" : "hotness")
    )

    show_more = false

    if stories.count > STORIES_PER_PAGE
      show_more = true
      stories.pop
    end

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

    # eager load comment counts
    if stories.any?
      comment_counts = {}
      Keystore.find(:all, :conditions => stories.map{|s|
      "`key` = 'story:#{s.id}:comment_count'" }.join(" OR ")).each do |ks|
        comment_counts[ks.key[/\d+/].to_i] = ks.value
      end

      stories.each do |s|
        s._comment_count = comment_counts[s.id].to_i
      end
    end

    [ stories, show_more ]
  end
end
