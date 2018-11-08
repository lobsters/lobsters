class LoginBannedError < StandardError; end
class LoginDeletedError < StandardError; end
class LoginTOTPFailedError < StandardError; end
class LoginWipedError < StandardError; end
class LoginFailedError < StandardError; end

class LoginController < ApplicationController
  before_action :authenticate_user
  before_action :check_for_read_only_mode, :except => [:index]

  def logout
    if @user
      reset_session
    end

    redirect_to "/"
  end

  def index
    @title = "Login"
    @referer ||= request.referer
    render :action => "index"
  end

  def login
    if params[:email].to_s.match(/@/)
      user = User.where(:email => params[:email]).first
    else
      user = User.where(:username => params[:email]).first
    end

    fail_reason = nil

    begin
      if !user
        raise LoginFailedError
      end

      if user.is_wiped?
        raise LoginWipedError
      end

      if !user.authenticate(params[:password].to_s)
        raise LoginFailedError
      end

      if user.is_banned?
        raise LoginBannedError
      end

      if !user.is_active?
        raise LoginDeletedError
      end

      if !user.password_digest.to_s.match(/^\$2a\$#{BCrypt::Engine::DEFAULT_COST}\$/)
        user.password = user.password_confirmation = params[:password].to_s
        user.save
      end

      if user.has_2fa? && !Rails.env.development?
        session[:twofa_u] = user.session_token
        return redirect_to "/login/2fa"
      end

      session[:u] = user.session_token

      if (rd = session[:redirect_to]).present?
        session.delete(:redirect_to)
        return redirect_to rd
      elsif params[:referer].present?
        begin
          ru = URI.parse(params[:referer])
          if ru.host == Rails.application.domain
            return redirect_to ru.to_s
          end
        rescue => e
          Rails.logger.error "error parsing referer: #{e}"
        end
      end

      return redirect_to "/"
    rescue LoginWipedError
      fail_reason = "Your account was banned or deleted before the site changed admins. " <<
                    "Your email and password hash were wiped for privacy."
    rescue LoginBannedError
      fail_reason = "Your account has been banned."
    rescue LoginDeletedError
      fail_reason = "Your account has been deleted."
    rescue LoginTOTPFailedError
      fail_reason = "Your TOTP code was invalid."
    rescue LoginFailedError
      fail_reason = "Invalid e-mail address and/or password."
    end

    flash.now[:error] = fail_reason
    @referer = params[:referer]
    index
  end

  def forgot_password
    @title = "Reset Password"
    render :action => "forgot_password"
  end

  def reset_password
    @found_user = User.where("email = ? OR username = ?", params[:email], params[:email]).first

    if !@found_user
      flash.now[:error] = "Invalid e-mail address or username."
      return forgot_password
    end

    if @found_user.is_banned?
      flash.now[:error] = "Your acocunt has been banned."
      return forgot_password
    end

    if @found_user.is_wiped?
      flash.now[:error] = "It's not possible to reest your password " <<
                          "because your account was deleted before the site changed admins " <<
                          "and your email address was wiped for privacy."
      return forgot_password
    end

    @found_user.initiate_password_reset_for_ip(request.remote_ip)

    flash.now[:success] = "Password reset instructions have been e-mailed to you."
    return index
  end

  def set_new_password
    @title = "Reset Password"

    if (m = params[:token].to_s.match(/^(\d+)-/)) &&
       (Time.current - Time.zone.at(m[1].to_i)) < 24.hours
      @reset_user = User.where(:password_reset_token => params[:token].to_s).first
    end

    if @reset_user && !@reset_user.is_banned?
      if params[:password].present?
        @reset_user.password = params[:password]
        @reset_user.password_confirmation = params[:password_confirmation]
        @reset_user.password_reset_token = nil

        # this will get reset upon save
        @reset_user.session_token = nil

        if !@reset_user.is_active? && !@reset_user.is_banned?
          @reset_user.deleted_at = nil
        end

        if @reset_user.save && @reset_user.is_active?
          if @reset_user.has_2fa?
            flash[:success] = "Your password has been reset."
            return redirect_to "/login"
          else
            session[:u] = @reset_user.session_token
            return redirect_to "/"
          end
        else
          flash[:error] = "Could not reset password."
        end
      end
    else
      flash[:error] = "Invalid reset token.  It may have already been " <<
                      "used or you may have copied it incorrectly."
      return redirect_to forgot_password_path
    end
  end

  def twofa
    if (tmpu = find_twofa_user)
      Rails.logger.info "  Authenticated as user #{tmpu.id} " <<
                        "(#{tmpu.username}), verifying TOTP"
    else
      reset_session
      return redirect_to "/login"
    end
  end

  def twofa_verify
    if (tmpu = find_twofa_user) && tmpu.authenticate_totp(params[:totp_code])
      session[:u] = tmpu.session_token
      session.delete(:twofa_u)
      return redirect_to "/"
    else
      flash[:error] = "Your TOTP code did not match.  Please try again."
      return redirect_to "/login/2fa"
    end
  end

private

  def find_twofa_user
    if session[:twofa_u].present?
      return User.where(:session_token => session[:twofa_u]).first
    end
  end
end
