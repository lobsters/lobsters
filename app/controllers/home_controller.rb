class HomeController < ApplicationController
  STORIES_PER_PAGE = 25

  # how many points a story has to be bumped off the newest page
  HOT_STORY_POINTS = 5

  # how many days old a story can be to get on the bottom half of /newest
  NEWEST_DAYS_OLD = 3

  # for rss feeds, load the user's tag filters if a token is passed
  before_filter :find_user_from_rss_token, :only => [ :index, :newest ]

  def index
    @stories = find_stories

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
    @stories = find_stories({ :newest => true })

    @heading = @title = "Newest Stories"
    @cur_url = "/newest"
    @newest = true

    @rss_link = "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0 - Newest Items\" href=\"/newest.rss" <<
      (@user ? "?token=#{@user.rss_token}" : "") << "\" />"

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
    by_user = User.where(:username => params[:user]).first!

    @stories = find_stories({ :by_user => by_user })

    @heading = @title = "Newest Stories by #{by_user.username}"
    @cur_url = "/newest/#{by_user.username}"

    @newest = true
    @for_user = by_user.username

    render :action => "index"
  end

  def tagged
    @tag = Tag.where(:tag => params[:tag]).first!

    @stories = find_stories({ :tag => @tag })

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
  def find_stories(how = {})
    @page = 1
    if params[:page].to_i > 0
      @page = params[:page].to_i
    end

    # guest views have caching, but don't bother for logged-in users or dev or
    # when the user has tag filters
    if Rails.env == "development" || @user || tags_filtered_by_cookie.any?
      stories, @show_more = _find_stories(how)
    else
      stories, @show_more = Rails.cache.fetch("stories " <<
      "tag:#{how[:tag].try(:tag)} new:#{how[:newest]} page:#{@page.to_i} " <<
      "by:#{how[:by_user].try(:id)}", :expires_in => 45) do
        _find_stories(how)
      end
    end

    stories
  end

  def _find_stories(how)
    stories = Story.where(:is_expired => false)

    if @user && !(how[:newest] || how[:by_user])
      # exclude downvoted items
      stories = stories.where(
        Story.arel_table[:id].not_in(
          Vote.arel_table.where(
            Vote.arel_table[:user_id].eq(@user.id)
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
    if @user
      filtered_tag_ids = @user.tag_filters.map{|tf| tf.tag_id }
    else
      filtered_tag_ids = tags_filtered_by_cookie.map{|t| t.id }
    end

    if how[:tag]
      stories = stories.where(
        Story.arel_table[:id].in(
          Tagging.arel_table.where(
            Tagging.arel_table[:tag_id].eq(tag.id)
          ).project(
            Tagging.arel_table[:story_id]
          )
        )
      )
    elsif how[:by_user]
      stories = stories.where(:user_id => how[:by_user].id)
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

    if how[:newest] && @page == 1
      # try to help recently-submitted stories that didn't gain traction

      # grab the list of stories from the past n days, shifting out popular
      # stories that did gain traction
      story_ids = stories.select(:id, :upvotes, :downvotes).
        where(Story.arel_table[:created_at].gt(NEWEST_DAYS_OLD.days.ago)).
        order("stories.created_at DESC").
        reject{|s| s.score > HOT_STORY_POINTS }

      if story_ids.length > STORIES_PER_PAGE + 1
        # keep the top half (newest stories)
        keep_ids = story_ids[0 .. ((STORIES_PER_PAGE + 1) * 0.5)]
        story_ids = story_ids[keep_ids.length - 1 ... story_ids.length]

        # make the bottom half a random selection of older stories
        while keep_ids.length <= STORIES_PER_PAGE + 1
          story_ids.shuffle!
          keep_ids.push story_ids.shift
        end

        stories = Story.where(:id => keep_ids)
      end
    end

    stories = stories.includes(
      :user, :taggings => :tag
    ).limit(
      STORIES_PER_PAGE + 1
    ).offset(
      (@page - 1) * STORIES_PER_PAGE
    ).order(
      how[:newest] ? "stories.created_at DESC" : "hotness"
    ).to_a

    show_more = false
    if stories.count > STORIES_PER_PAGE
      show_more = true
      stories.pop
    end

    if @user
      votes = Vote.votes_by_user_for_stories_hash(@user.id, stories.map(&:id))

      stories.each do |s|
        if votes[s.id]
          s.vote = votes[s.id]
        end
      end
    end

    [ stories, show_more ]
  end
end
