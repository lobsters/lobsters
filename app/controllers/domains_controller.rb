class DomainsController < ApplicationController
  before_action :require_logged_in_admin
  before_action :set_domain, only: [:update, :edit, :unban]
  before_action :set_reason, only: [:update, :unban]

  def edit; end

  def update
    if @banned_reason.present?
      @domain.ban_by_user_for_reason!(@user, @banned_reason)
    else
      flash[:error] = "You must give a reason for the ban"
    end

    redirect_to edit_domain_path(name: @domain.domain)
  end

  def unban
    if @banned_reason.present?
      @domain.unban_by_user_for_reason!(@user, @banned_reason)
    else
      flash[:error] = "You must give a reason for the unban"
    end

    redirect_to edit_domain_path(name: @domain.domain)
  end

private

  def set_domain
    @domain = Domain.find_by(domain: params[:name])
  end

  def set_reason
    @banned_reason = params.dig('domain', 'banned_reason')
  end

  def path_of_form(domain)
    prms = { name: domain.domain }
    domain.banned_at ? unban_domain_path(prms) : update_domain_path(prms)
  end

  helper_method :path_of_form

  def caption_of_button(domain)
    domain.banned_at ? 'Unban' : 'Ban'
  end

  helper_method :caption_of_button
end
