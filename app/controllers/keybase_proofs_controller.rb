class KeybaseProofsController < ApplicationController
  before_action :require_logged_in_user, only: [:new, :create]
  before_action :check_new_params, only: :new
  before_action :check_user_matches, only: :new
  before_action :force_to_json, only: [:kbconfig]

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

  def kbconfig
    return render json: {} unless Keybase.enabled?
    @domain = Keybase.DOMAIN
    @name = Rails.application.name
    @brand_color = "#AC130D"
    @description = "Computing-focused community centered around link aggregation and discussion"
    @contacts = ["admin@#{Keybase.DOMAIN}"]
    # rubocop:disable Style/FormatStringToken
    @prefill_url = "#{new_keybase_proof_url}?kb_username=%{kb_username}&" \
      "kb_signature=%{sig_hash}&kb_ua=%{kb_ua}&username=%{username}"
    @profile_url = "#{u_url}/%{username}"
    @check_url = "#{u_url}/%{username}.json"
    # rubocop:enable Style/FormatStringToken
    @logo_black = "https://lobste.rs/small-black-logo.svg"
    @logo_full = "https://lobste.rs/full-color.logo.svg"
    @user_re = User.username_regex_s[1...-1]
  end

private

  def force_to_json
    request.format = :json
  end

  def check_user_matches
    unless case_insensitive_match?(@user.username, params[:username])
      flash[:error] = "not logged in as the correct user"
      return redirect_to settings_path
    end
  end

  def case_insensitive_match?(first_string, second_string)
    # can replace this with first_string.casecmp?(second_string) when ruby >= 2.4.6
    first_string.casecmp(second_string).zero?
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
