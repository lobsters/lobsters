class HomeController < ApplicationController
  include IntervalHelper

  caches_page :about, :chat, :index, :newest, :newest_by_user, :recent, :top, if: CACHE_PAGE

  # for rss feeds, load the user's tag filters if a token is passed
  before_action :find_user_from_rss_token, :only => [:index, :newest, :saved]
  before_action { @page = page }
  before_action :require_logged_in_user, :only => [:upvoted]

  def four_oh_four
    begin
      @title = "Resource Not Found"
      render :action => "404", :status => 404
    rescue ActionView::MissingTemplate
      render :html => ("<div class=\"box wide\">" <<
        "<div class=\"legend\">404</div>" <<
        "Resource not found" <<
        "</div>").html_safe, :layout => "application"
    end
  end

  def about
    begin
      @title = "About"
      render :action => "about"
    rescue ActionView::MissingTemplate
      render :html => ("<div class=\"box wide\">" <<
        "A mystery." <<
        "</div>").html_safe, :layout => "application"
    end
  end

  def chat
    begin
      @title = "Chat"
      render :action => "chat"
    rescue ActionView::MissingTemplate
      render :html => ("<div class=\"box wide\">" <<
        "<div class=\"legend\">Chat</div>" <<
        "Keep it on-site" <<
        "</div>").html_safe, :layout => "application"
    end
  end

  def privacy
    begin
      @title = "Privacy"
      render :action => "privacy"
    rescue ActionView::MissingTemplate
      render :html => ("<div class=\"box wide\">" <<
                      "You apparently have no privacy." <<
                      "</div>").html_safe, :layout => "application"
    end
  end

  def hidden
    @stories, @show_more = get_from_cache(hidden: true) {
      paginate stories.hidden
    }

    @heading = @title = "Hidden Stories"
    @cur_url = "/hidden"

    render :action => "index"
  end

  def index
    @stories, @show_more = get_from_cache(hottest: true) {
      paginate stories.hottest
    }

    @rss_link ||= {
      :title => "RSS 2.0",
      :href => user_token_link("/rss"),
    }
    @comments_rss_link ||= {
      :title => "Comments - RSS 2.0",
      :href => user_token_link("/comments.rss"),
    }

    @heading = @title = ""
    @cur_url = "/"

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        if @user
          @title = "Private feed for #{@user.username}"
          render :action => "rss", :layout => false
        else
          content = Rails.cache.fetch("rss", :expires_in => (60 * 2)) {
            render_to_string :action => "rss", :layout => false
          }
          render :plain => content, :layout => false
        end
      }
      format.json { render :json => @stories }
    end
  end

  def newest
    @stories, @show_more = get_from_cache(newest: true) {
      paginate stories.newest
    }

    @heading = @title = "Newest Stories"
    @cur_url = "/newest"

    @rss_link = {
      :title => "RSS 2.0 - Newest Items",
      :href => user_token_link("/newest.rss"),
    }

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
    by_user = User.find_by!(username: params[:user])

    @stories, @show_more = get_from_cache(by_user: by_user) {
      if @user && @user.is_moderator?
        paginate stories.newest_including_deleted_by_user(by_user)
      else
        paginate stories.newest_by_user(by_user)
      end
    }

    @heading = @title = "Newest Stories by #{by_user.username}"
    @cur_url = "/newest/#{by_user.username}"

    @newest = true
    @for_user = by_user.username

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        render :action => "rss", :layout => false
      }
      format.json { render :json => @stories }
    end
  end

  def recent
    @stories, @show_more = get_from_cache(recent: true) {
      paginate Story.recent(@user, filtered_tag_ids)
    }

    @heading = @title = "Recent Stories"
    @cur_url = "/recent"

    # our list is unstable because upvoted stories get removed, so point at /newest.rss
    @rss_link = { :title => "RSS 2.0 - Newest Items", :href => user_token_link("/newest.rss") }

    render :action => "index"
  end

  def saved
    @stories, @show_more = get_from_cache(hidden: true) {
      paginate stories.saved
    }

    @rss_link ||= {
      :title => "RSS 2.0",
      :href => user_token_link("/saved.rss"),
    }

    @heading = @title = "Saved Stories"
    @cur_url = "/saved"

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        if @user
          @title = "Private feed of saved stories for #{@user.username}"
        end
        render :action => "rss", :layout => false
      }
      format.json { render :json => @stories }
    end
  end

  def tagged
    @tag = Tag.where(:tag => params[:tag]).first!

    @stories, @show_more = get_from_cache(tag: @tag) {
      paginate stories.tagged(@tag)
    }

    @heading = @tag.tag
    @title = [@tag.tag, @tag.description].compact.join(' - ')
    @cur_url = tag_url(@tag.tag)

    @rss_link = {
      :title => "RSS 2.0 - Tagged #{@tag.tag} (#{@tag.description})",
      :href => "/t/#{@tag.tag}.rss",
    }

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
      format.json { render :json => @stories }
    end
  end

  def top
    @cur_url = "/top"
    length = time_interval(params[:length])
    @cur_url << "/#{params[:length]}"

    @stories, @show_more = get_from_cache(top: true, length: length) {
      paginate stories.top(length)
    }

    if length[:dur] > 1
      @heading = @title = "Top Stories of the Past #{length[:dur]} " <<
                          length[:intv] << "s"
    else
      @heading = @title = "Top Stories of the Past " << length[:intv]
    end

    render :action => "index"
  end

  def upvoted
    @stories, @show_more = get_from_cache(upvoted: true, user: @user) {
      paginate @user.upvoted_stories.order('votes.id DESC')
    }

    @heading = @title = "Your Upvoted Stories"
    @cur_url = "/upvoted"

    @rss_link = {
      :title => "RSS 2.0 - Your Upvoted Stories",
      :href => user_token_link("/upvoted.rss"),
    }

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

private

  def filtered_tag_ids
    if @user
      @user.tag_filters.map(&:tag_id)
    else
      tags_filtered_by_cookie.map(&:id)
    end
  end

  def stories
    StoryRepository.new(@user, exclude_tags: filtered_tag_ids)
  end

  def page
    p = params[:page].to_i
    if p == 0
      p = 1
    elsif p < 0 || p > (2 ** 32)
      raise ActionController::RoutingError.new("page out of bounds")
    end
    p
  end

  def paginate(scope)
    StoriesPaginator.new(scope, page, @user).get
  end

  def get_from_cache(opts = {}, &block)
    if Rails.env.development? || @user || tags_filtered_by_cookie.any?
      yield
    else
      key = opts.merge(page: page).sort.map {|k, v| "#{k}=#{v.to_param}" }.join(" ")
      begin
        Rails.cache.fetch("stories #{key}", :expires_in => 45, &block)
      rescue Errno::ENOENT => e
        Rails.logger.error "error fetching stories #{key}: #{e}"
        yield
      end
    end
  end

  def user_token_link(url)
    @user ? "#{url}?token=#{@user.rss_token}" : url
  end
end
