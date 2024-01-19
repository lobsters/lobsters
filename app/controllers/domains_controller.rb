# typed: false

class DomainsController < ApplicationController
  before_action :require_logged_in_admin
  before_action :find_or_initialize_domain, only: [:edit, :update]

  def create
    @domain = Domain.create!(domain: domain_params[:domain])
    @domain.ban_by_user_for_reason!(@user, domain_params[:banned_reason])
    flash[:success] = "Domain created and banned. Real short run."
    redirect_to domain_path(@domain)
  end

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
    params.require(:domain).permit(:banned_reason, :domain)
  end

  def find_or_initialize_domain
    @domain = Domain.find_or_initialize_by(domain: params[:id])
    session[:domain] = @domain
  end

  def path_of_form(domain)
    prms = {name: domain.domain}
    domain.banned_at ? unban_domain_path(prms) : update_domain_path(prms)
  end

  helper_method :path_of_form

  def caption_of_button(domain)
    if domain.new_record?
      "Create and Ban"
    else
      domain.banned_at ? "Unban" : "Ban"
    end
  end

  helper_method :caption_of_button
end
