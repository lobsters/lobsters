class SettingsController < ApplicationController
  before_filter :require_logged_in_user

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
    return redirect_to settings_url
  end

  def update
    @edit_user = @user.clone

    if @edit_user.update_attributes(user_params)
      flash.now[:success] = "Successfully updated settings."
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
      :pushover_user_key, :pushover_device, :pushover_sound,
      :mailing_list_mode
    )
  end
end
