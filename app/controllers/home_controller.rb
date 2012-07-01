class HomeController < ApplicationController
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
end
