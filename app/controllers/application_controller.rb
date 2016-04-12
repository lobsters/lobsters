class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user
  before_filter :increase_traffic_counter

  TRAFFIC_DECREMENTER = 0.25

  TAG_FILTER_COOKIE = :tag_filters

  def authenticate_user
    if session[:u] &&
    (user = User.where(:session_token => session[:u].to_s).first) &&
    user.is_active?
      @user = user
      Rails.logger.info "  Logged in as user #{@user.id} (#{@user.username})"
    end

    true
  end

  def increase_traffic_counter
    @traffic = 1.0

    Keystore.transaction do
      now_i = Time.now.to_i
      date_kv = Keystore.find_or_create_key_for_update("traffic:date", now_i)
      traffic_kv = Keystore.find_or_create_key_for_update("traffic:hits", 0)

      traffic = traffic_kv.value.to_i

      # don't increase traffic counter for bots or api requests
      unless agent_is_spider? || agent_via_tor? ||
      [ "json", "rss" ].include?(params[:format])
        traffic += 100
      end

      # every second, decrement traffic by some amount
      traffic -= (100.0 * (now_i - date_kv.value) * TRAFFIC_DECREMENTER).to_i

      # clamp to 100, 1000
      traffic = [ [ 100, traffic ].max, 10000 ].min

      @traffic = traffic * 0.01

      traffic_kv.value = traffic
      traffic_kv.save!

      date_kv.value = now_i
      date_kv.save!

      Rails.logger.info "  Traffic level: #{@traffic.to_i}"
    end

    true
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

  def require_logged_in_user_or_400
    if @user
      true
    else
      render :text => "not logged in", :status => 400
      return false
    end
  end

  @_tags_filtered = nil
  def tags_filtered_by_cookie
    @_tags_filtered ||= Tag.where(
      :tag => cookies[TAG_FILTER_COOKIE].to_s.split(",")
    )
  end

  def agent_is_spider?
    ua = request.env["HTTP_USER_AGENT"].to_s
    (ua == "" || ua.match(/(Google|bing)bot|Slurp|crawler/))
  end

  def agent_via_tor?
    request.remote_ip == "127.0.0.1"
  end

  def find_user_from_rss_token
    if !@user && request[:format] == "rss" && params[:token].to_s.present?
      @user = User.where(:rss_token => params[:token].to_s).first
    end
  end
end
