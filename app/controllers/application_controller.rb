# typed: false

class ApplicationController < ActionController::Base
  include IntervalHelper
  include Authenticatable

  protect_from_forgery
  before_action :geoblock_uk
  before_action :heinous_inline_partials, if: -> { Rails.env.development? }
  before_action :mini_profiler
  before_action :prepare_exception_notifier
  before_action :set_traffic_style
  around_action :n_plus_one_detection

  # 2023-10-07 one user in one of their browser envs is getting a CSRF failure, I'm reverting
  # because I'll be AFK a while.
  # after_action :clear_lobster_trap

  # match this nginx config for bypassing the file cache
  TAG_FILTER_COOKIE = :tag_filters
  CACHE_PAGE = proc { @user.blank? && cookies[TAG_FILTER_COOKIE].blank? && !Maxmind.uk?(request.remote_ip) }

  # Rails misdesign: if the /recent route doesn't support .rss, Rails calls it anyways and then
  # raises MissingTemplate when it's not handled, as if the app did something wrong (a prod 500!).
  unless Rails.env.development?
    rescue_from ActionController::UnknownFormat, ActionView::MissingTemplate do
      request.format = :html # required, despite format.any
      respond_to do |format|
        format.any { render "about/404", status: :not_found, content_type: "text/html" }
      end
    end
  end
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

  # clear Rails session cookie if not logged in so nginx uses the page cache
  # https://ryanfb.xyz/etc/2021/08/29/going_cookie-free_with_rails.html
  def clear_lobster_trap
    key = Rails.application.config.session_options[:key] # "lobster_trap"
    cookies.delete(key) if @user.blank?
    # this probably should test session.empty? && controller...
    request.session_options[:skip] = @user.blank? && controller_name != "login"
  end

  def find_user_from_rss_token
    if !@user && params[:format] == "rss" && params[:token].to_s.present?
      @user = User.where(rss_token: params[:token].to_s).first
    end
  end

  # https://lobste.rs/s/ukosa1
  def geoblock_uk
    return unless Time.current.utc >= Date.new(2025, 3, 16)
    return unless Maxmind.uk?(req.ip)

    render body: "I'm very sorry, but the risks of the UK Online Safety Act have required that Lobsters geoblock the UK. <a href=\"https://web.archive.org/web/*/https://lobste.rs/s/ukosa1\">Discussion</a>", status: 451, content_type: "text/html"
    false
  end

  def heinous_inline_partials
    do_heinous_inline_partial_replacement
  end

  def mini_profiler
    if @user&.is_moderator?
      Rack::MiniProfiler.authorize_request
    end
  end

  def prepare_exception_notifier
    exception_data = {}
    exception_data[:username] = @user.username unless @user.nil?

    request.env["exception_notifier.exception_data"] = exception_data
  end

  # https://web.archive.org/web/20180108083712/http://umaine.edu/lobsterinstitute/files/2011/12/LobsterColorsWeb.pdf
  def set_traffic_style
    @traffic_intensity = "?"
    @traffic_style = "background-color: #ac130d;"
    return true if Rails.application.read_only? ||
      agent_is_spider? ||
      %w[json rss].include?(params[:format])
    return if (@traffic_novelty = TrafficHelper.novelty_logo)

    @traffic_intensity = TrafficHelper.cached_current_intensity
    # map intensity to 80-255 so there's always a little red
    hex = sprintf("%02x", (@traffic_intensity * 1.75 + 80).round)
    @traffic_style = "background-color: ##{hex}0000;"
    return true unless @user

    color = :red
    [
      [2_000_000, :blue, "background-color: #0000#{hex};"],
      [6, :yellow, "background-color: ##{hex}#{hex}00;"],
      [3, :calico, "background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAACXBIWXMAAC4jAAAuIwF4pT92AAAABmJLR0QA/wD/AP+gvaeTAAACpElEQVQYGQXBWW8bVRgA0Hu/u814NsdxGsUxztJUzaJSVS1CCCTKE7zxxiP/gH+I+lKKQEVCLUlJ5YTsU8f2eJvxbHfjHLz7sKeU2mhNfvl579vnEPKUEUJxji1YoBaIob4m6+cX8Our/m99TBwmpKGV0hZjz+EO06FHOAKlFNKIcE+p8HYo3rwd/Xk8m+pVEjW4EzIFdjopVVG6Nt1ocpc3ALnIhqMRnF3afz6qd2flcMElAOWu3nm4tr6xMh2cyDpprqwBwdjQ0Uz9fXJ9el0lRTOekVQ13DCKvCXVWO7sdl6+/Gp01cbpv/uHPcqGlUKIr50NZq+Pi7mymrt+GOxvbz9+zKjS5OLi1uV/ZeObAC3un4qgt+c0bL8/v5qJ64WbaocIPC2HzbaDGCOeF0ySJI7vzz9eLuZFpfDq2lZWmd/fx6/e3twkuDIiL3KCysV83D+/xZ/1uhYXjuC6lg0BVk2fHPXcQMWD7L+bvJCettzhEPpgzRIxjbe3u6VMCcXWMEY5E9qisqo1QlRLjDVwxqxSQpBW5CFnSB2PaulyRleCSEtNhDPLltjkdQWYCC+gDVF6pHzU8z8/7IKgVFaVtshSWaQxA2Osz4FiokTQrLRrQCLIXzxr/fT94cFWVFlGmXExNQznnbbzaGcVgb0bJqO8kS5BzmusNAMdYN5mPlsihRh5sL7pRYHXQM+OOj/+8MV3Xx+2mmQ8qQZxkmfKSGXq1Odyt9MShByffKLgcc3JsqrHk3Eyumu6LbkYFHcfsjttSaR5OFP29H755nzw/sq8+yMh/sYKYiRL76dxzOqr9RBsmeisnCWqVlZaMIyxgC5U9eEy7p9awj0ByDiQ7XfgmyfRl0fRwZbb7bLVNmOOXynADDY3Hxzs7+WL5XSY/w/0MGrkMYhXjAAAAABJRU5ErkJggg==) no-repeat center"],
      [2, :split, "background: linear-gradient(90deg, ##{hex}0000 50%, #0000#{hex} 50%)"],
      [2, :albino, "filter: invert(100%);"]
    ].each do |cumulative_odds, name, style|
      break unless rand(cumulative_odds) == 0
      color = name
      @traffic_style = style
    end
    if color != :red
      Rails.logger.info "  Lucky user #{@user.username} saw #{color} logo"
    end
  end

  def require_no_user_or_redirect
    redirect_to "/" if @user
  end

  def show_title_h1
    @title_h1 = true
  end

  def tags_filtered_by_cookie
    @_tags_filtered ||= Tag.where(
      tag: cookies[TAG_FILTER_COOKIE].to_s.split(",")
    )
  end

  def n_plus_one_detection
    Prosopite.scan
    yield
  ensure
    Prosopite.finish
  end
end
