class LoginController < ApplicationController
  before_filter :authenticate_user

  def logout
    if @user
      reset_session
    end

    redirect_to "/"
  end

  def index
    @title = "Login"
    render :action => "index"
  end

  def login
    if params[:email].to_s.match(/@/)
      user = User.where(:email => params[:email]).first
    else
      user = User.where(:username => params[:email]).first
    end

    if user && user.is_active? &&
    user.try(:authenticate, params[:password].to_s)
      session[:u] = user.session_token
      return redirect_to "/"
    end

    flash.now[:error] = "Invalid e-mail address and/or password."
    index
  end

  def forgot_password
    @title = "Reset Password"
    render :action => "forgot_password"
  end

  def reset_password
    @found_user = User.where("email = ? OR username = ?", params[:email].to_s,
      params[:email].to_s).first

    if !@found_user
      flash.now[:error] = "Invalid e-mail address or username."
      return forgot_password
    end

    @found_user.initiate_password_reset_for_ip(request.remote_ip)

    flash.now[:success] = "Password reset instructions have been e-mailed " <<
      "to you."
    return index
  end

  def set_new_password
    @title = "Reset Password"

    if params[:token].blank? ||
    !(@reset_user = User.where(:password_reset_token => params[:token].to_s).first)
      flash[:error] = "Invalid reset token.  It may have already been " <<
        "used or you may have copied it incorrectly."
      return redirect_to forgot_password_url
    end

    if params[:password].present?
      @reset_user.password = params[:password]
      @reset_user.password_confirmation = params[:password_confirmation]
      @reset_user.password_reset_token = nil

      # this will get reset upon save
      @reset_user.session_token = nil

      if @reset_user.save && @reset_user.is_active?
        session[:u] = @reset_user.session_token
        return redirect_to "/"
      end
    end
  end
end
