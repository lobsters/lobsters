class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user
  before_filter :send_css_link_header
  before_filter :increase_traffic_counter

  @@_css_link_header = nil

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

  # speed hax
  @@_css_link_header = nil
  def send_css_link_header
    if !Rails.env.development?
      begin
        if !@@_css_link_header
          # is there a better way to find this?
          j = JSON.parse(File.read(Dir.glob(
            "#{Rails.root}/public/assets/manifest-*.json").first))

          @@_css_link_header = "</assets/" << j["assets"]["application.css"] <<
            ">; rel=stylesheet"
        end
      rescue => e
        Rails.logger.error e.inspect
      end

      if @@_css_link_header
        response.headers["Link"] = @@_css_link_header
      end
    end
  end

  def increase_traffic_counter
    @traffic = 1.0

    if user_is_spider? || [ "json", "rss" ].include?(params[:format])
      return true
    end

    Keystore.transaction do
      now_i = Time.now.to_i
      date_kv = Keystore.find_or_create_key_for_update("traffic:date", now_i)
      traffic_kv = Keystore.find_or_create_key_for_update("traffic:hits", 0)

      # increment traffic counter on each request
      traffic = traffic_kv.value.to_i + 100
      # every second, decrement traffic by some amount
      traffic -= (100.0 * (now_i - date_kv.value) * TRAFFIC_DECREMENTER).to_i
      # clamp
      traffic = [ 100, traffic ].max

      @traffic = traffic * 0.01

      traffic_kv.value = traffic
      traffic_kv.save!

      date_kv.value = now_i
      date_kv.save!
    end

    Rails.logger.info "  Traffic level: #{@traffic}"

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

  def user_is_spider?
    ua = request.env["HTTP_USER_AGENT"].to_s
    (ua == "" || ua.match(/(Google|bing)bot/))
  end

  def find_user_from_rss_token
    if !@user && request[:format] == "rss" && params[:token].to_s.present?
      @user = User.where(:rss_token => params[:token].to_s).first
    end
  end
end
