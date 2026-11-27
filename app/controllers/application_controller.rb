class ApplicationController < ActionController::Base
  include IntervalHelper
  include Authenticatable
  include ApplicationHelper

  protect_from_forgery prepend: true, with: :exception
  prepend_before_action :prepare_exception_notifier # first in case others raise
  before_action :mini_profiler
  before_action :set_traffic_style
  before_action :remove_unknown_cookies
  after_action :clear_session_cookie

  SESSION_DEFAULT_KEYS = %w[session_id _csrf_token]
  # match this in caddy config for bypassing the file cache
  TAG_FILTER_COOKIE = :tag_filters
  CACHE_PAGE = proc { @user.blank? && cookies[TAG_FILTER_COOKIE].blank? && clear_session_cookie? }

  # copied from https://github.com/rack/rack/blob/main/lib/rack/utils.rb
  VALID_COOKIE_KEY = /\A[!#$%&'*+\-.\^_`|~0-9a-zA-Z]+\z/
  ANUBIS_COOKIE_PREFIX = "techaro.lol-anubis"

  rescue_from ActionController::UnpermittedParameters do
    respond_to do |format|
      format.html { render plain: "400 Unpermitted query or form parameter", status: :bad_request }
      format.json { render json: {error: "400 Unpermitted query or form parameter"}, status: :bad_request }
    end
  end
  rescue_from ActionController::ParameterMissing do |exception|
    respond_to do |format|
      format.html { render plain: "400 #{exception.message}", status: :bad_request }
      format.json { render json: {error: exception.message.to_s}, status: :bad_request }
    end
  end
  rescue_from ActionDispatch::Http::MimeNegotiation::InvalidType do
    render plain: "fix the mime type in your HTTP_ACCEPT header",
      status: :bad_request, content_type: "text/plain"
  end
  rescue_from ActionDispatch::RemoteIp::IpSpoofAttackError do
    render plain: RejectSpoofedIps::MESSAGE, status: :bad_request, content_type: "text/plain"
  end
  rescue_from ActiveRecord::ConnectionNotEstablished do
    render plain: "500 The database is not taking our calls.", status: 500, content_type: "text/plain"
  end
  rescue_from ActionController::InvalidAuthenticityToken do
    render plain: "422 Invalid CSRF token. Reload the form and try again.", status: :unprocessable_content
  end

  def agent_is_spider?
    ua = request.env["HTTP_USER_AGENT"].to_s
    ua == "" || ua.match(/(Google|bing|Slack|Twitter)bot|Slurp|crawler|Feedly|FeedParser|RSS/)
  end

  def check_for_read_only_mode
    if Rails.application.read_only?
      flash.now[:error] = "Site is currently in read-only mode."
      return redirect_to "/"
    end

    true
  end

  def remove_unknown_cookies
    cookies.each do |key, _value|
      next if key == TAG_FILTER_COOKIE.to_s # don't clear tag filters cookie
      next if key == Rails.application.config.session_options[:key] # don't clear session cookie
      next if key == "__profilin" && (Rails.env.development? || @user&.is_moderator?) # don't clear Rack::MiniProfiler cookie
      next if key.start_with?(ANUBIS_COOKIE_PREFIX)
      next unless VALID_COOKIE_KEY.match?(key)
      cookies.delete(key)
    end
  end

  # clear Rails session cookie if not logged in so caddy uses the page cache
  # https://ryanfb.xyz/etc/2021/08/29/going_cookie-free_with_rails.html
  def clear_session_cookie
    if clear_session_cookie?
      key = Rails.application.config.session_options[:key] # "lobster_trap"
      cookies.delete(key)
      request.session_options[:skip] = true
    end
  end

  def clear_session_cookie?
    # If the session has been loaded, it will contain some default keys and not
    # be `empty?`
    !@user && session.keys.all? { |k| SESSION_DEFAULT_KEYS.include?(k.to_s) } && flash.empty?
  end

  def find_user_from_rss_token
    if !@user && params[:format] == "rss" && params[:token].to_s.present?
      @user = User.where(rss_token: params[:token].to_s).first
      Telebugs.user id: @user&.token, username: @user&.username, email: @user&.email, ip_address: request.remote_ip
    end
  end

  def mini_profiler
    if @user&.is_moderator?
      Rack::MiniProfiler.authorize_request
    end
  end

  def prepare_exception_notifier
    if Rails.application.config.exception_notifier
      exception_data = {}
      exception_data[:username] = @user.username unless @user.nil?
      request.env["exception_notifier.exception_data"] = exception_data
    end

    Telebugs.context "request", {
      request_token: request.request_id,
      requested_path: @requested_path,
      original_fullpath: request.original_fullpath,
      query_parameters: request.query_parameters, # protected by filter_parameters
      request_parameters: request.request_parameters, # protected by filter_parameters
      git_head: LOBSTERS_GIT_HEAD
    }
    Telebugs.user id: nil, username: nil, email: nil, ip_address: request.remote_ip # authenticate_user overwrites
  end

  def refill_story_page_cache(story, is_moderator: false)
    # an unauthed hit to an edit action would fail to load @story, then call this
    return if !story

    if (story.is_gone? || story.merged_story_id || story.new_record?) && story.short_id.present? && page_cache_directory.present?
      # rm the story's whole directory to catch files with old title slugs
      story_dir = File.join(page_cache_directory, "s", story.short_id)
      FileUtils.rm_rf [story_dir, *Dir.glob("#{story_dir}.*")]
    else
      path = Routes.title_path(story)
      return unless is_moderator || Rails.cache.write("refill_story_page_cache:#{path}", true, unless_exist: true, expires_in: 2.minutes)

      CachePageJob
        .set(
          queue: (is_moderator || story.created_at&.after?(1.month.ago)) ? :default : :refill_story_pages
        )
        .perform_later(path)
    end
  end

  # https://web.archive.org/web/20180108083712/http://umaine.edu/lobsterinstitute/files/2011/12/LobsterColorsWeb.pdf
  def set_traffic_style
    @traffic_intensity = "?"
    @traffic_bg_color = "#ac130d"
    return true if Rails.application.read_only? ||
      agent_is_spider? ||
      %w[json rss].include?(params[:format])
    return if (@traffic_logo = TrafficHelper.novelty_logo)

    @traffic_intensity = TrafficHelper.cached_current_intensity
    # map intensity to 80-255 so there's always a little red
    hex = sprintf("%02x", (@traffic_intensity * 1.75 + 80).round)
    @traffic_bg_color = "##{hex}0000"
    return true unless @user

    [
      [2_000_000, :blue, "#0000#{hex}"],
      [6, :yellow, "##{hex}#{hex}00"],
      [3, :calico, "none"],
      [2, :split, "##{hex}0000"],
      [2, :albino, "#000000"]
    ].each do |cumulative_odds, name, bg_color|
      break unless rand(cumulative_odds) == 0
      @traffic_logo = name
      @traffic_bg_color = bg_color
    end
  end

  def require_no_user_or_redirect
    redirect_to "/" if @user
  end

  def show_title_h1
    @title_h1 = true
  end
end
