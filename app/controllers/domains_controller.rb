class DomainsController < ApplicationController
  before_action :require_logged_in_admin
  before_action :set_domain, only: [:update, :edit, :ban]

  def edit; end

  def update
    result_domain_name =
      if @domain.update(domain_params)
        flash[:success] = "Domain #{@domain.domain} has been updated"
        @domain.domain
      else
        flash[:error] = "Domain not updated: #{@domain.errors.full_messages.join(', ')}"
        params[:domain_name]
      end

    redirect_to edit_domain_path(domain_name: result_domain_name)
  end

  def ban
    banned_reason = params.dig('domain', 'banned_reason')
    if banned_reason.present?
      @domain.ban_by_user_for_reason!(@user, banned_reason)
    else
      flash[:error] = "You must give a reason for the ban"
    end

    redirect_to edit_domain_path(domain_name: @domain.domain)
  end

private

  def set_domain
    @domain = Domain.find_by(domain: params[:domain_name])
  end

  def domain_params
    params.require(:domain).permit(:domain)
  end
end
