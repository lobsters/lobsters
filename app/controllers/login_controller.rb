# typed: false

class LoginBannedError < StandardError; end

class LoginDeletedError < StandardError; end

class LoginTOTPFailedError < StandardError; end

class LoginWipedError < StandardError; end

class LoginFailedError < StandardError; end

class LoginController < ApplicationController
  before_action :authenticate_user
  before_action :check_for_read_only_mode, except: [:index]
  before_action :require_no_user_or_redirect,
    only: [:index, :login, :forgot_password, :reset_password]
  before_action :show_title_h1

  def logout
    if @user
      reset_session
    end

    redirect_to "/"
  end

  def index
    @title = "Login"
    @referer ||= request.referer
  end

  def aqora_auth
    session[:aqora_state] = SecureRandom.hex
    redirect_to Aqora.oauth_auth_url(session[:aqora_state]), allow_other_host: true
  end

  def aqora_callback
    if session[:aqora_state].blank? ||
        params[:code].blank? ||
        (params[:state].to_s != session[:aqora_state].to_s)
      flash[:error] = 'Invalid OAuth state'
      return redirect_to '/settings'
    end

    session.delete(:aqora_state)

    begin
      aqora_user = Aqora.oauth_callback_user(request.url)
    rescue AqoraOAuth2TokenError, AqoraOAuth2ClientError, AqoraOAuth2ViewerError
      flash.now[:error] = 'There was an retrieving your account.'
      return render '/login'
    rescue AqoraOAuth2UnauthorizedError
      flash.now[:error] = 'Your aqora account is not authorized to access this site.'
      return render '/login'
    end

    user = User.where(aqora_id: aqora_user.id).first

    unless user
      begin
        user = User.create!(
          aqora_id: aqora_user.id,
          username: aqora_user.username,
          email: aqora_user.email,
          homepage: aqora_user.website,
          about: aqora_user.bio,
          github_username: aqora_user.github
        )
        flash[:success] = "Welcome to #{Rails.application.name}, " \
          "#{user.username}!"
      rescue ActiveRecord::RecordInvalid => e
        flash.now[:error] = "There was an error creating your account: #{e}"
        return render '/login'
      end
    end

    if user.is_wiped?
      flash.now[:error] = 'Your account was banned or deleted before the site changed admins. ' \
        'Your email and password hash were wiped for privacy.'
      return render 'index'
    end

    if user.is_banned?
      flash.now[:error] = "Your account has been banned. Log: #{user.banned_reason}"
      return render 'index'
    end

    unless user.is_active?
      flash.now[:error] = 'Your account has been deleted.'
      return render 'index'
    end

    session[:u] = user.session_token

    if (rd = session[:redirect_to]).present?
      session.delete(:redirect_to)
      return redirect_to rd
    elsif params[:referer].present?
      begin
        ru = URI.parse(params[:referer])
        return redirect_to ru.to_s if ru.host == Rails.application.domain
      rescue StandardError => e
        Rails.logger.error "error parsing referer: #{e}"
      end
    end

    redirect_to root_path
  end

  def login
    @title = "Login"
    user = if /@/.match?(params[:email].to_s)
      User.where(email: params[:email]).first
    else
      User.where(username: params[:email]).first
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

      if !user.password_digest.to_s.match(/^\$2a\$#{BCrypt::Engine::DEFAULT_COST}\$/o)
        user.password = user.password_confirmation = params[:password].to_s
        user.save!
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
      fail_reason = "Your account was banned or deleted before the site changed admins. " \
        "Your email and password hash were wiped for privacy."
    rescue LoginBannedError
      fail_reason = "Your account has been banned. Log: #{user.banned_reason}"
    rescue LoginDeletedError
      fail_reason = "Your account has been deleted."
    rescue LoginTOTPFailedError
      fail_reason = "Your TOTP code was invalid."
    rescue LoginFailedError
      fail_reason = "Invalid e-mail address and/or password."
    end

    flash.now[:error] = fail_reason
    @referer = params[:referer]
    render "index"
  end

  def forgot_password
    @title = "Reset Password"
  end

  def reset_password
    @title = "Reset Password"
    @found_user = User.where("email = ? OR username = ?", params[:email], params[:email]).first

    if !@found_user
      flash.now[:error] = "Unknown e-mail address or username."
      return forgot_password
    end

    if @found_user.is_banned?
      flash.now[:error] = "Your account has been banned."
      return forgot_password
    end

    if @found_user.is_wiped?
      flash.now[:error] = "It's not possible to reset your password " \
        "because your account was deleted before the site changed admins " \
        "and your email address was wiped for privacy."
      return forgot_password
    end

    @found_user.initiate_password_reset_for_ip(request.remote_ip)

    flash.now[:success] = "Password reset instructions have been e-mailed to you."
    render "index"
  end

  def set_new_password
    @title = "Set New Password"

    if (m = params[:token].to_s.match(/^(\d+)-/)) &&
        (Time.current - Time.zone.at(m[1].to_i)) < 24.hours
      @reset_user = User.where(password_reset_token: params[:token].to_s).first
    end

    if @reset_user && !@reset_user.is_banned?
      if params[:password].present?
        @reset_user.password = params[:password]
        @reset_user.password_confirmation = params[:password_confirmation]
        @reset_user.password_reset_token = nil
        @reset_user.roll_session_token

        if !@reset_user.is_active? && !@reset_user.is_banned?
          @reset_user.deleted_at = nil
        end

        if @reset_user.save && @reset_user.is_active?
          if @reset_user.has_2fa?
            flash[:success] = "Your password has been reset."
            redirect_to "/login"
          else
            session[:u] = @reset_user.session_token
            redirect_to "/"
          end
        else
          flash[:error] = "Could not reset password."
        end
      end
    else
      flash[:error] = "Invalid reset token.  It may have already been " \
        "used or you may have copied it incorrectly."
      redirect_to forgot_password_path
    end
  end

  def twofa
    @title = "Login - Two Factor Authentication"
    if (tmpu = find_twofa_user)
      Rails.logger.info "  Authenticated as user #{tmpu.id} " \
        "(#{tmpu.username}), verifying TOTP"
    else
      reset_session
      redirect_to "/login"
    end
  end

  def twofa_verify
    @title = "Login - Two Factor Authentication"
    if (tmpu = find_twofa_user) && tmpu.authenticate_totp(params[:totp_code])
      session[:u] = tmpu.session_token
      session.delete(:twofa_u)
      redirect_to "/"
    else
      flash[:error] = "Your TOTP code did not match.  Please try again."
      redirect_to "/login/2fa"
    end
  end

  private

  def find_twofa_user
    if session[:twofa_u].present?
      User.where(session_token: session[:twofa_u]).first
    end
  end
end
