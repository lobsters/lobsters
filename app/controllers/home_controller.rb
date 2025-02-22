# typed: false

class HomeController < ApplicationController
  include IntervalHelper

  caches_page :active, :index, :newest, :newest_by_user, :recent, :top, if: CACHE_PAGE

  # for rss feeds, load the user's tag filters if a token is passed
  before_action :find_user_from_rss_token, only: [:index, :newest, :saved, :upvoted]
  before_action { @page = page }
  before_action :require_logged_in_user, only: [:hidden, :saved, :upvoted]
  before_action :show_title_h1, only: [:top]

  def active
    @stories, @show_more = get_from_cache(active: true) {
      paginate stories.active
    }

    @title = "Active Discussions"
    @above = {partial: "active"}

    respond_to do |format|
      format.html { render action: :index }
      format.json { render json: @stories }
    end
  end

  def hidden
    @stories, @show_more = get_from_cache(hidden: true) {
      paginate stories.hidden
    }

    @title = "Hidden Stories"
    @above = {partial: "saved/subnav"}

    render action: "index"
  end

  def index
    @stories, @show_more = get_from_cache(hottest: true) {
      paginate stories.hottest
    }

    @rss_link ||= {
      title: "RSS 2.0",
      href: user_token_link("/rss")
    }
    @comments_rss_link ||= {
      title: "Comments - RSS 2.0",
      href: user_token_link("/comments.rss")
    }

    @title = ""
    @root_path = true

    respond_to do |format|
      format.html { render action: "index" }
      format.rss {
        if @user
          @title = "Private feed for #{@user.username}"
          render action: "stories", layout: false
        else
          content = Rails.cache.fetch("rss", expires_in: (60 * 2)) {
            render_to_string action: "stories", layout: false
          }
          render plain: content, layout: false
        end
      }
      format.json { render json: @stories }
    end
  end

  def newest
    @stories, @show_more = get_from_cache(newest: true) {
      paginate stories.newest
    }

    @title = "Newest Stories"
    @above = {partial: "stories/subnav"}
    @last_read_story = find_last_read_story

    @rss_link = {
      title: "RSS 2.0 - Newest Items",
      href: user_token_link("/newest.rss")
    }

    respond_to do |format|
      format.html { render action: "index" }
      format.rss {
        if @user && params[:token].present?
          @title += " - Private feed for #{@user.username}"
        end

        render action: "stories", layout: false
      }
      format.json { render json: @stories }
    end

    @user&.touch(:last_read_newest) if @last_read_story || @user&.last_read_newest.nil?
  end

  def newest_by_user
    by_user = User.find_by!(username: params[:user])

    @stories, @show_more = paginate stories.newest_by_user(by_user)

    @title = "Newest Stories by #{by_user.username}"
    @above = {partial: "newest_by_user", locals: {newest_by_user: by_user}}

    respond_to do |format|
      format.html { render action: "index" }
      format.rss {
        render action: "stories", layout: false
      }
      format.json { render json: @stories }
    end
  end

  def recent
    @stories, @show_more = get_from_cache(recent: true) {
      paginate Story.recent(@user, filtered_tag_ids)
    }

    @title = "Recent Stories"
    @above = {partial: "stories/subnav"}
    @below = {partial: "recent"}

    # our list is unstable because upvoted stories get removed, so point at /newest.rss
    @rss_link = {title: "RSS 2.0 - Newest Items", href: user_token_link("/newest.rss")}

    render action: "index"
  end

  def saved
    @stories, @show_more = get_from_cache(hidden: true) {
      paginate stories.saved
    }

    @rss_link ||= {
      title: "RSS 2.0",
      href: user_token_link("/saved.rss")
    }

    @title = "Saved Stories"
    @above = {partial: "saved/subnav"}

    respond_to do |format|
      format.html { render action: "index" }
      format.rss {
        if @user
          @title = "Private feed of saved stories for #{@user.username}"
        end
        render action: "stories", layout: false
      }
      format.json { render json: @stories }
    end
  end

  def category
    category_params = params[:category].split(",")
    categories = Category.where(category: category_params)

    raise ActiveRecord::RecordNotFound unless categories.length == category_params.length

    @stories, @show_more = get_from_cache(categories: category_params.sort.join(",")) do
      paginate stories.categories(categories)
    end

    @title = categories.map(&:category).join(" ")
    @above = {partial: "category", locals: {categories: categories}}

    @rss_link = {
      title: "RSS 2.0 - Categorized #{@title}",
      href: category_url(params[:category], format: "rss")
    }

    respond_to do |format|
      format.html { render action: "index" }
      format.rss { render action: "stories", layout: false }
      format.json { render json: @stories }
    end
  end

  def single_tag
    @tag = Tag.find_by!(tag: params[:tag])

    @stories, @show_more = get_from_cache(tag: @tag.tag) do
      paginate stories.tagged([@tag])
    end

    @related = Rails.cache.fetch("related_#{@tag.tag}", expires_in: 1.day) {
      Tag.related(@tag)
    }
    @title = [@tag.tag, @tag.description].compact.join(" - ")
    @above = {partial: "single_tag", locals: {tag: @tag, related: @related}}
    @below = {partial: "tags/multi_tag_tip"}

    @rss_link = {
      title: "RSS 2.0 - Tagged #{@tag.tag} (#{@tag.description})",
      href: "/t/#{@tag.tag}.rss"
    }

    respond_to do |format|
      format.html { render action: "index" }
      format.rss { render action: "stories", layout: false }
      format.json { render json: @stories }
    end
  end

  def multi_tag
    tag_params = params[:tag].split(",")
    @tags = Tag.where(tag: tag_params)
    raise ActiveRecord::RecordNotFound unless @tags.length == tag_params.length

    @stories, @show_more = get_from_cache(tags: tag_params.sort.join(",")) do
      paginate stories.tagged(@tags)
    end

    @title = @tags.map do |tag|
      [tag.tag, tag.description].compact.join(" - ")
    end.join(" ")
    @above = {partial: "multi_tag", locals: {tags: @tags}}

    @rss_link = {
      title: "RSS 2.0 - Tagged #{tags_with_description_for_rss(@tags)}",
      href: "/t/#{params[:tag]}.rss"
    }

    respond_to do |format|
      format.html { render action: "index" }
      format.rss { render action: "stories", layout: false }
      format.json { render json: @stories }
    end
  end

  def for_domain
    @domain = Domain.find_by!(domain: params[:id])

    @stories, @show_more = get_from_cache(domain: @domain.domain) do
      paginate @domain.stories.base(@user).order(id: :desc)
    end

    @title = @domain.domain
    @above = {partial: "for_domain", locals: {domain: @domain, stories: @stories}}

    @rss_link = {
      title: "RSS 2.0 - For #{@domain.domain}",
      href: "/domains/#{@domain.domain}.rss"
    }

    respond_to do |format|
      format.html { render action: "index" }
      format.rss { render action: "stories", layout: false }
      format.json { render json: @stories }
    end
  end

  def for_origin
    @origin = Origin.find_by!(identifier: params[:identifier])

    @stories, @show_more = get_from_cache(identifier: @origin.identifier) do
      paginate @origin.stories.base(@user).order(id: :desc)
    end

    @title = @origin.identifier
    @above = {partial: "for_origin", locals: {origin: @origin, stories: @stories}}

    @rss_link = {
      title: "RSS 2.0 - For #{@origin.identifier}",
      href: "/origins/#{@origin.identifier}.rss"
    }

    respond_to do |format|
      format.html { render action: "index" }
      format.rss { render action: "stories", layout: false }
      format.json { render json: @stories }
    end
  end

  def top
    length = time_interval(params[:length])

    @stories, @show_more = get_from_cache(top: true, length: length) {
      paginate stories.top(length)
    }

    @title = if length[:dur] > 1
      "Top Stories of the Past #{length[:dur]} #{length[:intv]}"
    else
      "Top Stories of the Past #{length[:intv]}"
    end
    @above = "stories/subnav"

    @rss_link ||= {
      title: "RSS 2.0 - " + @title,
      href: "/top/rss"
    }

    respond_to do |format|
      format.html { render action: "index" }
      format.rss { render action: "stories", layout: false }
    end
  end

  def upvoted
    @stories, @show_more = get_from_cache(upvoted: true, user: @user) {
      paginate @user.upvoted_stories.includes(:tags).order("votes.id DESC")
    }

    @title = "Upvoted Stories"
    @above = "saved/subnav"

    @rss_link = {
      title: "RSS 2.0 - Upvoted Stories",
      href: user_token_link("/upvoted.rss")
    }

    respond_to do |format|
      format.html { render action: :index }
      format.rss {
        if @user && params[:token].present?
          @title += " - Private feed for #{@user.username}"
        end

        render action: "stories", layout: false
      }
      format.json { render json: @stories }
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
    elsif p < 0 || p > (2**32)
      raise ActionController::RoutingError.new("page out of bounds")
    end
    p
  end

  def paginate(scope)
    StoriesPaginator.new(scope, page, @user).get
  end

  def get_from_cache(opts = {}, &)
    if Rails.env.development? || @user || tags_filtered_by_cookie.any?
      yield
    else
      key = opts.merge(page: page).sort.map { |k, v| "#{k}=#{v.to_param}" }.join(" ")
      begin
        Rails.cache.fetch("stories #{key}", expires_in: 45, &)
      rescue Errno::ENOENT => e
        # Rails.logger.error "error fetching stories #{key}: #{e}"
        yield
      end
    end
  end

  def user_token_link(url)
    @user ? "#{url}?token=#{@user.rss_token}" : url
  end

  def tags_with_description_for_rss(tags)
    tags.map { |tag| "#{tag.tag} (#{tag.description})" }.join(" ")
  end

  def find_last_read_story
    @stories.find { |story| @user&.last_read_newest&.after?(story.created_at) }
  end
end
