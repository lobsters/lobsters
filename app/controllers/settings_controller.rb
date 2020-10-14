class SettingsController < ApplicationController
  before_action :require_logged_in_user

  TOTP_SESSION_TIMEOUT = (60 * 15)

  def index
    @title = "Account Settings"

    @edit_user = @user.dup
  end

  def delete_account
    unless params[:user][:i_am_sure].present?
      flash[:error] = 'You did not check the "I am sure" checkbox.'
      return redirect_to settings_path
    end
    unless @user.try(:authenticate, params[:user][:password].to_s)
      flash[:error] = "Given password doesn't match account."
      return redirect_to settings_path
    end

    @user.delete!
    disown_text = ""
    if params[:user][:disown].present?
      disown_text = " and disowned your stories and comments."
      InactiveUser.disown_all_by_author! @user
    end
    reset_session
    flash[:success] = "You have deleted your account#{disown_text}. Bye."
    return redirect_to "/"
  end

  def update
    previous_username = @user.username
    @edit_user = @user.clone

    if params[:user][:password].empty? ||
       @user.authenticate(params[:current_password].to_s)
      if @edit_user.update(user_params)
        if @edit_user.username != previous_username
          Moderation.create!(
            is_from_suggestions: true,
            user: @edit_user,
            action: "changed own username from \"#{previous_username}\" " <<
                    "to \"#{@edit_user.username}\"",
          )
        end
        flash.now[:success] = "Successfully updated settings."
        @user = @edit_user
      end
    else
      flash[:error] = "Your current password was not entered correctly."
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
      session[:totp_secret] = ROTP::Base32.random
    end

    totp = ROTP::TOTP.new(session[:totp_secret], :issuer => Rails.application.name)
    totp_url = totp.provisioning_uri(@user.email)

    # no option for inline svg, so just strip off leading <?xml> tag
    qrcode = RQRCode::QRCode.new(totp_url)
    qr = qrcode.as_svg(offset: 0,
                       color: "000",
                       module_size: 5,
                       shape_rendering: "crispEdges").gsub(/^<\?xml.*>/, "")

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

      flash[:success] = "Two-Factor Authentication has been enabled on your account."
      session.delete(:totp_secret)
      return redirect_to "/settings"
    else
      flash[:error] = "Your TOTP code was invalid, please verify the " <<
                      "current code in your TOTP application."
      return redirect_to twofa_verify_url
    end
  end

  # external services

  def pushover_auth
    if !Pushover.SUBSCRIPTION_CODE
      flash[:error] = "This site is not configured for Pushover"
      return redirect_to "/settings"
    end

    session[:pushover_rand] = SecureRandom.hex

    return redirect_to Pushover.subscription_url(
      :success => "#{Rails.application.root_url}settings/pushover_callback?" <<
        "rand=#{session[:pushover_rand]}",
      :failure => "#{Rails.application.root_url}settings/",
    )
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
      raise "rand param #{params[:rand].inspect} != #{session[:pushover_rand].inspect}"
    end

    @user.pushover_user_key = params[:pushover_user_key].to_s
    @user.save!

    if @user.pushover_user_key.present?
      flash[:success] = "Your account is now setup for Pushover notifications."
    else
      flash[:success] = "Your account is no longer setup for Pushover notifications."
    end

    return redirect_to "/settings"
  end

  def github_auth
    session[:github_state] = SecureRandom.hex
    return redirect_to Github.oauth_auth_url(session[:github_state])
  end

  def github_callback
    if !session[:github_state].present? ||
       !params[:code].present? ||
       (params[:state].to_s != session[:github_state].to_s)
      flash[:error] = "Invalid OAuth state"
      return redirect_to "/settings"
    end

    session.delete(:github_state)

    tok, username = Github.token_and_user_from_code(params[:code])
    if tok.present? && username.present?
      @user.github_oauth_token = tok
      @user.github_username = username
      @user.save!
      flash[:success] = "Your account has been linked to GitHub user #{username}."
    else
      return github_disconnect
    end

    return redirect_to "/settings"
  end

  def github_disconnect
    @user.github_oauth_token = nil
    @user.github_username = nil
    @user.save!
    flash[:success] = "Your GitHub association has been removed."
    return redirect_to "/settings"
  end

  def twitter_auth
    session[:twitter_state] = SecureRandom.hex
    return redirect_to Twitter.oauth_auth_url(session[:twitter_state])
  rescue OAuth::Unauthorized
    flash[:error] = "Twitter says we're not authenticating properly, please message the admin"
    return redirect_to "/settings"
  end

  def twitter_callback
    if session[:twitter_state].blank? ||
       (params[:state].to_s != session[:twitter_state].to_s)
      flash[:error] = "Invalid OAuth state"
      return redirect_to "/settings"
    end

    session.delete(:twitter_state)

    tok, sec, username = Twitter.token_secret_and_user_from_token_and_verifier(
      params[:oauth_token], params[:oauth_verifier])
    if tok.present? && username.present?
      @user.twitter_oauth_token = tok
      @user.twitter_oauth_token_secret = sec
      @user.twitter_username = username
      @user.save!
      flash[:success] = "Your account has been linked to Twitter user @#{username}."
    else
      return twitter_disconnect
    end

    return redirect_to "/settings"
  end

  def twitter_disconnect
    @user.twitter_oauth_token = nil
    @user.twitter_username = nil
    @user.twitter_oauth_token_secret = nil
    @user.save!
    flash[:success] = "Your Twitter association has been removed."
    return redirect_to "/settings"
  end

private

  def user_params
    params.require(:user).permit(
      :username, :email, :password, :password_confirmation, :homepage, :about,
      :email_replies, :email_messages, :email_mentions,
      :pushover_replies, :pushover_messages, :pushover_mentions,
      :mailing_list_mode, :show_avatars, :show_story_previews,
      :show_submitted_story_threads
    )
  end
end
