class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user
  before_filter :increase_traffic_counter

  TRAFFIC_DECREMENTER = 0.25

  TAG_FILTER_COOKIE = :tag_filters

  def authenticate_user
    if session[:u]
      @user = User.where(:session_token => session[:u].to_s).first
    end

    true
  end

  def increase_traffic_counter
    @traffic = 1.0

    if user_is_spider? || [ "json", "rss" ].include?(params[:format])
      return true
    end

    Keystore.transaction do
      date = (Keystore.value_for("traffic:date") || Time.now.to_i)
      traffic = (Keystore.incremented_value_for("traffic:hits", 0).
        to_f / 100.0) + 1.0

      # every second, decrement traffic by some amount
      @traffic = [ 1.0, traffic.to_f -
        ((Time.now.to_i - date) * TRAFFIC_DECREMENTER) ].max

      Keystore.put("traffic:date", Time.now.to_i)
      Keystore.put("traffic:hits", (@traffic * 100.0).to_i)
    end

    Rails.logger.info "  Traffic level: #{@traffic}"

    true
  end

  def require_logged_in_user
    if @user
      true
    else
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
    !!request.env["HTTP_USER_AGENT"].to_s.match(/Googlebot/)
  end

  def find_user_from_rss_token
    if !@user && request[:format] == "rss" && params[:token].to_s.present?
      @user = User.where(:rss_token => params[:token].to_s).first
    end
  end
end
