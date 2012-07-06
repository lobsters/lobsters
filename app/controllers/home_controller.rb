class HomeController < ApplicationController
  STORIES_PER_PAGE = 20

  def index
    @stories = find_stories_for_user_and_tag_and_newest(@user, nil, false)

    @rss_link ||= "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0\" href=\"/rss\" />"

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
    end
  end

  def newest
    @stories = find_stories_for_user_and_tag_and_newest(@user, nil, true)

    @page_title = "Newest Stories"

    @rss_link = "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0 - Newest Items\" href=\"/newest.rss\" />"

    @title = "Newest Stories"
    @title_url = "/newest"
    @newest = true

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
    end
  end

  def tagged
    @tag = Tag.find_by_tag!(params[:tag])
    @stories = find_stories_for_user_and_tag_and_newest(@user, @tag, false)

    @page_title = @tag.description

    @rss_link = "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0 - Tagged #{CGI.escape(@tag.tag)} " <<
      "(#{CGI.escape(@tag.description)})\" href=\"/t/" +
      "#{CGI.escape(@tag.tag)}.rss\" />"

    @title = @tag.description.blank?? @tag.tag : @tag.description
    @title_url = tag_url(@tag.tag)

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
    end
  end

private
  def find_stories_for_user_and_tag_and_newest(user, tag = nil, newest = false)
    conds = [ "is_expired = 0 AND is_moderated = 0 " ]

    if user && !newest
      # exclude downvoted items
      conds[0] << "AND stories.id NOT IN (SELECT story_id FROM votes " <<
        "WHERE user_id = ? AND vote < 0) "
      conds.push user.id
    end

    if tag
      conds[0] << "AND taggings.tag_id = ?"
      conds.push tag.id
    elsif user
      conds[0] += " AND taggings.tag_id NOT IN (SELECT tag_id FROM " <<
        "tag_filters WHERE user_id = ?)"
      conds.push @user.id
    end

    @page = 1
    if params[:page].to_i > 0
      @page = params[:page].to_i
    end

    stories = Story.find(
      :all,
      :conditions => conds,
      :include => [ :user, { :taggings => :tag } ],
      :limit => STORIES_PER_PAGE + 1,
      :offset => ((@page - 1) * STORIES_PER_PAGE),
      :order => (newest ? "stories.created_at DESC" : "hotness")
    )

    @show_more = false

    if stories.count > STORIES_PER_PAGE
      @show_more = true
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

    stories
  end
end
