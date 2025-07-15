module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user
  end

  def authenticate_user
    # eagerly evaluate, in case this triggers an IpSpoofAttackError
    request.remote_ip

    if Rails.application.read_only?
      return true
    end

    if session[:u] &&
        (user = User.find_by(session_token: session[:u].to_s)) &&
        user.is_active?
      @user = user
      Telebugs.user id: @user.token, username: @user.username, email: @user.email, ip_address: request.remote_ip
    end

    true
  end

  def require_logged_in_moderator
    require_logged_in_user

    if @user
      if @user.is_moderator?
        true
      else
        flash[:error] = "You are not authorized to access that resource."
        redirect_to "/"
      end
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

  def require_logged_in_admin
    require_logged_in_user

    if @user
      if @user.is_admin?
        true
      else
        flash[:error] = "You are not authorized to access that resource."
        redirect_to "/"
      end
    end
  end

  def require_logged_in_user_or_401
    if @user
      true
    else
      respond_to do |format|
        format.html { render plain: "not logged in", status: 401 }
        format.json { render json: {error: "not logged in"}, status: 401 }
      end
      false
    end
  end
end
