class SettingsController < ApplicationController
  before_filter :require_logged_in_user

  def index
    @title = t('.accountsettings')

    @edit_user = @user.dup
  end

  def delete_account
    if @user.try(:authenticate, params[:user][:password].to_s)
      @user.delete!
      reset_session
      flash[:success] = t('.deleteaccountflash')
      return redirect_to "/"
    end

    flash[:error] = t('.verifypasswordflash')
    return redirect_to settings_path
  end

  def pushover
    if !Pushover.SUBSCRIPTION_CODE
      flash[:error] = t('.pushovernotconfigured')
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
      flash[:error] = t('.pushovernorandomtokensession')
      return redirect_to "/settings"
    end

    if !params[:rand].to_s.present?
      flash[:error] = t('.pushovernorandomtokenurl')
      return redirect_to "/settings"
    end

    if params[:rand].to_s != session[:pushover_rand].to_s
      raise "rand param #{params[:rand].inspect} != " <<
        session[:pushover_rand].inspect
    end

    @user.pushover_user_key = params[:pushover_user_key].to_s
    @user.save!

    if @user.pushover_user_key.present?
      flash[:success] = t('.accountsetuppushover')
    else
      flash[:success] = t('.accountnolongersetuppushover')
    end

    return redirect_to "/settings"
  end

  def update
    @edit_user = @user.clone

    if @edit_user.update_attributes(user_params)
      flash.now[:success] = t('.updatesettingsflash')
      @user = @edit_user
    end

    render :action => "index"
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
