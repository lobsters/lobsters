class ApplicationController < ActionController::Base
  include IntervalHelper

  protect_from_forgery
  before_action :authenticate_user
  before_action :set_traffic_style
  before_action :prepare_exception_notifier

  # match this in your nginx config for bypassing the file cache
  TAG_FILTER_COOKIE = :tag_filters

  # returning false until 1. nginx wants to serve cached files
  # 2. the "stay logged in" cookie is separated from rails session cookie
  # (lobster_trap) which is sent even to logged-out visitors
  CACHE_PAGE = proc { false && @user.blank? && cookies[TAG_FILTER_COOKIE].blank? }

  rescue_from ActionController::UnknownFormat, ActionView::MissingTemplate do
    render plain: '404 Not Found', status: :not_found, content_type: 'text/plain'
  end

  def authenticate_user
    # eagerly evaluate, in case this triggers an IpSpoofAttackError
    request.remote_ip

    if Rails.application.read_only?
      return true
    end

    if session[:u] &&
       (user = User.find_by(:session_token => session[:u].to_s)) &&
       user.is_active?
      @user = user
    end
    Rails.logger.info(
      "  Request #{request.remote_ip} #{request.request_method} #{request.fullpath} user: " +
      (@user ? "#{@user.id} #{@user.username}" : "0 nobody")
    )

    true
  end

  def check_for_read_only_mode
    if Rails.application.read_only?
      flash.now[:error] = "Site is currently in read-only mode."
      return redirect_to "/"
    end

    true
  end

  def flag_warning
    @flag_warning_int = time_interval('1m')
    @show_flag_warning = (
      @user && !!DownvotedCommenters.new(@flag_warning_int[:param], 1.day).check_list_for(@user)
    )
  end

  # https://web.archive.org/web/20180108083712/http://umaine.edu/lobsterinstitute/files/2011/12/LobsterColorsWeb.pdf
  def set_traffic_style
    @traffic_intensity = '?'
    @traffic_style = 'background-color: #ac130d;'
    return true if Rails.application.read_only? ||
                   agent_is_spider? ||
                   %w{json rss}.include?(params[:format])

    @traffic_intensity = TrafficHelper.cached_current_intensity
    # map intensity to 80-255 so there's always a little red
    hex = sprintf('%02x', (@traffic_intensity * 1.75 + 80).round)
    @traffic_style = "background-color: ##{hex}0000;"
    return true unless @user

    color = :red
    [
      # rubocop:disable Metrics/LineLength,
      [2_000_000, :blue, "background-color: #0000#{hex};"],
      [6, :yellow, "background-color: ##{hex}#{hex}00;"],
      [3, :calico, "background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAACXBIWXMAAC4jAAAuIwF4pT92AAAABmJLR0QA/wD/AP+gvaeTAAACpElEQVQYGQXBWW8bVRgA0Hu/u814NsdxGsUxztJUzaJSVS1CCCTKE7zxxiP/gH+I+lKKQEVCLUlJ5YTsU8f2eJvxbHfjHLz7sKeU2mhNfvl579vnEPKUEUJxji1YoBaIob4m6+cX8Our/m99TBwmpKGV0hZjz+EO06FHOAKlFNKIcE+p8HYo3rwd/Xk8m+pVEjW4EzIFdjopVVG6Nt1ocpc3ALnIhqMRnF3afz6qd2flcMElAOWu3nm4tr6xMh2cyDpprqwBwdjQ0Uz9fXJ9el0lRTOekVQ13DCKvCXVWO7sdl6+/Gp01cbpv/uHPcqGlUKIr50NZq+Pi7mymrt+GOxvbz9+zKjS5OLi1uV/ZeObAC3un4qgt+c0bL8/v5qJ64WbaocIPC2HzbaDGCOeF0ySJI7vzz9eLuZFpfDq2lZWmd/fx6/e3twkuDIiL3KCysV83D+/xZ/1uhYXjuC6lg0BVk2fHPXcQMWD7L+bvJCettzhEPpgzRIxjbe3u6VMCcXWMEY5E9qisqo1QlRLjDVwxqxSQpBW5CFnSB2PaulyRleCSEtNhDPLltjkdQWYCC+gDVF6pHzU8z8/7IKgVFaVtshSWaQxA2Osz4FiokTQrLRrQCLIXzxr/fT94cFWVFlGmXExNQznnbbzaGcVgb0bJqO8kS5BzmusNAMdYN5mPlsihRh5sL7pRYHXQM+OOj/+8MV3Xx+2mmQ8qQZxkmfKSGXq1Odyt9MShByffKLgcc3JsqrHk3Eyumu6LbkYFHcfsjttSaR5OFP29H755nzw/sq8+yMh/sYKYiRL76dxzOqr9RBsmeisnCWqVlZaMIyxgC5U9eEy7p9awj0ByDiQ7XfgmyfRl0fRwZbb7bLVNmOOXynADDY3Hxzs7+WL5XSY/w/0MGrkMYhXjAAAAABJRU5ErkJggg==) no-repeat center"],
      [2, :split, "background: linear-gradient(90deg, ##{hex}0000 50%, #0000#{hex} 50%)"],
      [2, :albino, "filter: invert(100%);"],
      # rubocop:enable Metrics/LineLength,
    ].each do |cumulative_odds, name, style|
      break unless rand(cumulative_odds) == 0
      color = name
      @traffic_style = style
    end
    if color != :red
      Rails.logger.info "  Lucky user #{@user.username} saw #{color} logo"
    end
  end

  def require_logged_in_user
    if @user
      true
    else
      if request.get?
        session[:redirect_to] = request.original_fullpath
      end

      redirect_to "/login"
    end
  end

  def require_logged_in_moderator
    require_logged_in_user

    if @user
      if @user.is_moderator?
        true
      else
        flash[:error] = "You are not authorized to access that resource."
        return redirect_to "/"
      end
    end
  end

  def require_logged_in_admin
    require_logged_in_user

    if @user
      if @user.is_admin?
        true
      else
        flash[:error] = "You are not authorized to access that resource."
        return redirect_to "/"
      end
    end
  end

  def require_logged_in_user_or_400
    if @user
      true
    else
      render :plain => "not logged in", :status => 400
      return false
    end
  end

  def require_no_user_or_redirect
    return redirect_to "/" if @user
  end

  def tags_filtered_by_cookie
    @_tags_filtered ||= Tag.where(
      :tag => cookies[TAG_FILTER_COOKIE].to_s.split(",")
    )
  end

  def agent_is_spider?
    ua = request.env["HTTP_USER_AGENT"].to_s
    (ua == "" || ua.match(/(Google|bing|Slack|Twitter)bot|Slurp|crawler|Feedly|FeedParser|RSS/))
  end

  def find_user_from_rss_token
    if !@user && request[:format] == "rss" && params[:token].to_s.present?
      @user = User.where(:rss_token => params[:token].to_s).first
    end
  end

  def prepare_exception_notifier
    exception_data = {}
    exception_data[:username] = @user.username unless @user.nil?

    request.env["exception_notifier.exception_data"] = exception_data
  end
end
