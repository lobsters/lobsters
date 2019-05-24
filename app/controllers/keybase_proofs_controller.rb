class KeybaseProofsController < ApplicationController
  before_action :require_logged_in_user
  before_action :check_new_params, only: :new
  before_action :check_user_matches, only: :new

  def new
    @kb_username = params[:kb_username]
    @kb_signature = params[:kb_signature]
    @kb_ua = params[:kb_ua]
    @kb_avatar = Keybase.avatar_url(@kb_username)
  end

  def create
    kb_username = post_params[:kb_username]
    kb_signature = post_params[:kb_signature]
    kb_ua = post_params[:kb_ua]
    if Keybase.proof_valid?(kb_username, kb_signature, @user.username)
      @user.add_or_update_keybase_proof(kb_username, kb_signature)
      @user.save!
      return redirect_to Keybase.success_url(kb_username, kb_signature, kb_ua, @user.username)
    else
      flash[:error] = "Failed to connect your account to Keybase. Try again from Keybase."
      return redirect_to settings_path
    end
  end

private

  def check_user_matches
    unless @user.username.casecmp(params[:username]).zero?
      flash[:error] = "not logged in as the correct user"
      return redirect_to settings_path
    end
  end

  def post_params
    params.require(:keybase_proof).permit(:kb_username, :kb_signature, :kb_ua, :username)
  end

  def check_new_params
    redirect_to settings_path unless [:kb_username, :kb_signature, :kb_ua, :username].all? do |k|
      params[k].present?
    end
  end
end
