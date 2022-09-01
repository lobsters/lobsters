class DomainsController < ApplicationController
  before_action :require_logged_in_admin
  before_action :find_domain, only: [:edit, :update]

  def edit; end

  def update
    if domain_params[:banned_reason].present?
      if @domain.banned?
        @domain.unban_by_user_for_reason!(@user, domain_params[:banned_reason])
      else
        @domain.ban_by_user_for_reason!(@user, domain_params[:banned_reason])
      end
      flash[:success] = "Domain updated."
      redirect_to domain_path(@domain)
    else
      flash.now[:error] = "Reason required for the modlog."
      render :edit
    end
  end

private

  def domain_params
    params.require(:domain).permit(:banned_reason)
  end

  def find_domain
    @domain = Domain.find_by(domain: params[:id])
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
