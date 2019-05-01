class LoginBannedError < StandardError; end
class LoginDeletedError < StandardError; end
class LoginTOTPFailedError < StandardError; end
class LoginFailedError < StandardError; end

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

      if !user.authenticate(params[:password].to_s)
        # if the user has 2fa enabled and the password looks like it has a totp
        # code attached, separate them
        if user.has_2fa? &&
        (m = params[:password].to_s.match(/\A(.+):(\d+)\z/)) &&
        user.authenticate(m[1])
          params[:password] = m[1]
          params[:totp] = m[2]
        else
          raise LoginFailedError
        end
      end

      if user.is_banned?
        raise LoginBannedError
      end

      if !user.is_active?
        raise LoginDeletedError
      end

      if !user.password_digest.to_s.match(/^\$2a\$#{BCrypt::Engine::DEFAULT_COST}\$/)
        user.password = user.password_confirmation = params[:password].to_s
        user.save!
      end

      if user.has_2fa?
        if params[:totp].present?
          if user.authenticate_totp(params[:totp])
            # ok, fall through
          else
            raise LoginTOTPFailedError
          end
        else
          return respond_to do |format|
            format.html {
              session[:twofa_u] = user.session_token
              redirect_to "/login/2fa"
            }
            format.json {
              render :json => { :status => 0,
                :error => "must supply totp parameter" }
            }
          end
        end
      end

      return respond_to do |format|
        format.html {
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

          redirect_to "/"
        }
        format.json {
          render :json => { :status => 1, :username => user.username }
        }
      end
    rescue LoginBannedError
      fail_reason = I18n.t 'controllers.login_controller.bannedaccount'
    rescue LoginDeletedError
      fail_reason = I18n.t 'controllers.login_controller.deletedaccount'
    rescue LoginTOTPFailedError
      fail_reason = I18n.t 'controllers.login_controller.totpinvalid'
    rescue LoginFailedError
      fail_reason = I18n.t 'controllers.login_controller.flashlogininvalid'
    end

    respond_to do |format|
      format.html {
        flash.now[:error] = fail_reason
        @referer = params[:referer]
        index
      }
      format.json {
        render :json => { :status => 0, :error => fail_reason }
      }
    end
  end

  def forgot_password
    @title = "Reimposta Password"
    render :action => "forgot_password"
  end

  def reset_password
    @found_user = User.where("email = ? OR username = ?", params[:email].to_s,
      params[:email].to_s).first

    if !@found_user
      flash.now[:error] = "Username o password non corretti"
      return forgot_password
    end

    @found_user.initiate_password_reset_for_ip(request.remote_ip)

    flash.now[:success] = "Le istruzioni per il recupero della password ti sono state inviate via e-mail"
    return index
  end

  def set_new_password
    @title = "Reimposta Password"

    if (m = params[:token].to_s.match(/^(\d+)-/)) &&
    (Time.now - Time.at(m[1].to_i)) < 24.hours
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
            flash[:success] = t('.passwordreset')
            return redirect_to "/login"
          else
            session[:u] = @reset_user.session_token
            return redirect_to "/"
          end
        else
          flash[:error] = t('.couldnotresetpassword')
        end
      end
    else
      flash[:error] = t('.invalidresettoken')
      return redirect_to forgot_password_path
    end
  end

  def twofa
    if tmpu = find_twofa_user
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
      flash[:error] = t('.totpcodenotmatch')
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
