# typed: false

class DomainsBanController < DomainsController
  before_action :require_logged_in_moderator
  before_action :find_or_initialize_domain

  def create_and_ban
    @domain = Domain.create!(domain: params[:id])
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
end
