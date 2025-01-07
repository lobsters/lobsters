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

  def require_logged_in_user_or_400
    if @user
      true
    else
      render plain: "not logged in", status: 400
      false
    end
  end
end
