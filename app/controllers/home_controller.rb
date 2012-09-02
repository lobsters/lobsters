class HomeController < ApplicationController
  STORIES_PER_PAGE = 25

  def index
    @stories = find_stories_for_user_and_tag_and_newest(@user, nil, false)

    @rss_link ||= "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0\" href=\"/rss\" />"

    @title = ""
    @cur_url = "/"

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
    end
  end

  def newest
    @stories = find_stories_for_user_and_tag_and_newest(@user, nil, true)

    @title = "Newest Stories"
    @cur_url = "/newest"

    @rss_link = "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0 - Newest Items\" href=\"/newest.rss\" />"

    @newest = true

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
    end
  end

  def tagged
    @tag = Tag.find_by_tag!(params[:tag])
    @stories = find_stories_for_user_and_tag_and_newest(@user, @tag, false)

    @title = @tag.description.blank?? @tag.tag : @tag.description
    @cur_url = tag_url(@tag.tag)

    @rss_link = "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0 - Tagged #{CGI.escape(@tag.tag)} " <<
      "(#{CGI.escape(@tag.description)})\" href=\"/t/" +
      "#{CGI.escape(@tag.tag)}.rss\" />"

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
    end
  end

private
  def find_stories_for_user_and_tag_and_newest(user, tag = nil, newest = false)
    @page = 1
    if params[:page].to_i > 0
      @page = params[:page].to_i
    end

    # guest views have caching, but don't bother for logged-in users
    if user
      stories, @show_more = _find_stories_for_user_and_tag_and_newest(user,
        tag, newest)
    else
      stories, @show_more = Rails.cache.fetch("stories tag:" <<
      "#{tag ? tag.tag : ""} new:#{newest} page:#{@page.to_i}",
      :expires_in => 45) do
        _find_stories_for_user_and_tag_and_newest(user, tag, newest)
      end
    end

    stories
  end

  def _find_stories_for_user_and_tag_and_newest(user, tag = nil, newest = false)
    conds = [ "is_expired = 0 " ]

    if user && !newest
      # exclude downvoted items
      conds[0] << "AND stories.id NOT IN (SELECT story_id FROM votes " <<
        "WHERE user_id = ? AND vote < 0 AND comment_id IS NULL) "
      conds.push user.id
    end

    if tag
      conds[0] << "AND stories.id IN (SELECT taggings.story_id FROM " <<
        "taggings WHERE taggings.tag_id = ?)"
      conds.push tag.id
    elsif user
      conds[0] += " AND taggings.tag_id NOT IN (SELECT tag_id FROM " <<
        "tag_filters WHERE user_id = ?)"
      conds.push @user.id
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
