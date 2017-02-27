class SettingsController < ApplicationController
  before_filter :require_logged_in_user

  TOTP_SESSION_TIMEOUT = (60 * 15)

  def index
    @title = "Account Settings"

    @edit_user = @user.dup
  end

  def delete_account
    if @user.try(:authenticate, params[:user][:password].to_s)
      @user.delete!
      reset_session
      flash[:success] = "Your account has been deleted."
      return redirect_to "/"
    end

    flash[:error] = "Your password could not be verified."
    return redirect_to settings_path
  end

  def pushover
    if !Pushover.SUBSCRIPTION_CODE
      flash[:error] = "This site is not configured for Pushover"
      return redirect_to "/settings"
    end

    session[:pushover_rand] = SecureRandom.hex

    return redirect_to Pushover.subscription_url({
      :success => "#{Rails.application.root_url}settings/pushover_callback?" <<
        "rand=#{session[:pushover_rand]}",
      :failure => "#{Rails.application.root_url}settings/",
    })
  end

  def pushover_callback
    if !session[:pushover_rand].to_s.present?
      flash[:error] = "No random token present in session"
      return redirect_to "/settings"
    end

    if !params[:rand].to_s.present?
      flash[:error] = "No random token present in URL"
      return redirect_to "/settings"
    end

    if params[:rand].to_s != session[:pushover_rand].to_s
      raise "rand param #{params[:rand].inspect} != " <<
        session[:pushover_rand].inspect
    end

    @user.pushover_user_key = params[:pushover_user_key].to_s
    @user.save!

    if @user.pushover_user_key.present?
      flash[:success] = "Your account is now setup for Pushover notifications."
    else
      flash[:success] = "Your account is no longer setup for Pushover " <<
        "notifications."
    end

    return redirect_to "/settings"
  end

  def update
    @edit_user = @user.clone

    if params[:user][:password].empty? ||
    @user.authenticate(params[:current_password].to_s)
      if @edit_user.update_attributes(user_params)
        flash.now[:success] = "Successfully updated settings."
        @user = @edit_user
      end
    else
      flash[:error] = "Your password was not correct."
    end

    render :action => "index"
  end

  def twofa
    @title = "Two-Factor Authentication"
  end

  def twofa_auth
    if @user.authenticate(params[:user][:password].to_s)
      session[:last_authed] = Time.now.to_i
      session.delete(:totp_secret)

      if @user.has_2fa?
        @user.disable_2fa!
        flash[:success] = "Two-Factor Authentication has been disabled."
        return redirect_to "/settings"
      else
        return redirect_to twofa_enroll_url
      end
    else
      flash[:error] = "Your password was not correct."
      return redirect_to twofa_url
    end
  end

  def twofa_enroll
    @title = "Two-Factor Authentication"

    if (Time.now.to_i - session[:last_authed].to_i) > TOTP_SESSION_TIMEOUT
      flash[:error] = "Your enrollment period timed out."
      return redirect_to twofa_url
    end

    if !session[:totp_secret]
      session[:totp_secret] = ROTP::Base32.random_base32
    end

    totp = ROTP::TOTP.new(session[:totp_secret],
      :issuer => Rails.application.name)
    totp_url = totp.provisioning_uri(@user.email)

    # no option for inline svg, so just strip off leading <?xml> tag
    qrcode = RQRCode::QRCode.new(totp_url)
    qr = qrcode.as_svg(:offset => 0, color: "000", :module_size => 5,
      :shape_rendering => "crispEdges").gsub(/^<\?xml.*>/, "")

    @qr_svg = "<a href=\"#{totp_url}\">#{qr}</a>"
  end

  def twofa_verify
    @title = "Two-Factor Authentication"

    if ((Time.now.to_i - session[:last_authed].to_i) > TOTP_SESSION_TIMEOUT) ||
    !session[:totp_secret]
      flash[:error] = "Your enrollment period timed out."
      return redirect_to twofa_url
    end
  end

  def twofa_update
    if ((Time.now.to_i - session[:last_authed].to_i) > TOTP_SESSION_TIMEOUT) ||
    !session[:totp_secret]
      flash[:error] = "Your enrollment period timed out."
      return redirect_to twofa_url
    end

    @user.totp_secret = session[:totp_secret]
    if @user.authenticate_totp(params[:totp_code])
      # re-roll, just in case
      @user.session_token = nil
      @user.save!

      session[:u] = @user.session_token

      flash[:success] = "Two-Factor Authentication has been enabled on " <<
        "your account."
      session.delete(:totp_secret)
      return redirect_to "/settings"
    else
      flash[:error] = "Your TOTP code was invalid, please verify the " <<
        "current code in your TOTP application."
      return redirect_to twofa_verify_url
    end
  end

private

  def user_params
    params.require(:user).permit(
      :username, :email, :password, :password_confirmation, :about,
      :email_replies, :email_messages, :email_mentions,
      :pushover_replies, :pushover_messages, :pushover_mentions,
      :mailing_list_mode, :show_avatars, :show_story_previews,
      :show_submitted_story_threads, :hide_dragons
    )
  end
end
