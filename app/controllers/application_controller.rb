class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user

  def authenticate_user
    if session[:u]
      @user = User.find_by_session_token(session[:u])
    end

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
end
