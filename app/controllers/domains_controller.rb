class DomainsController < ApplicationController
  before_action :require_logged_in_admin
  before_action :set_domain, only: [:update, :edit, :unban]

  def edit; end

  def update
    banned_reason = params.dig('domain', 'banned_reason')
    if banned_reason.present?
      @domain.ban_by_user_for_reason!(@user, banned_reason)
    else
      flash[:error] = "You must give a reason for the ban"
    end

    redirect_to edit_domain_path(name: @domain.domain)
  end

  def unban
    @domain.unban_by_user!(@user)
    redirect_to edit_domain_path(name: @domain.domain)
  end

private

  def set_domain
    @domain = Domain.find_by(domain: params[:name])
  end
end
