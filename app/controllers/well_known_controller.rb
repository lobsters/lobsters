class WellKnownController < ApplicationController
  before_action :set_default_response_format

  def keybase
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

  def set_default_response_format
    request.format = :json
  end
end
