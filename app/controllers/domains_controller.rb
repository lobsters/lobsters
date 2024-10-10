# typed: false

class DomainsController < ApplicationController
  before_action :require_logged_in_moderator, only: [:edit, :update]
  before_action :find_or_initialize_domain, only: [:edit, :update]

  def create
    @domain = Domain.new(domain: params[:new_domain])
    @domain.selector = domain_params[:selector]
    @domain.replacement = domain_params[:replacement]

    if @domain.save
      flash[:success] = "Domain created"
      redirect_to domain_path(@domain)
    else
      render :edit
    end
  end

  def edit
  end

  def update
    @domain.assign_attributes(domain_params)
    if @domain.save
      flash[:success] = "Domain edited"
      redirect_to domain_path(@domain)
    else
      render :edit
    end
  end

  private

  def domain_params
    params.require(:domain).permit(:banned_reason, :selector, :replacement)
  end

  def find_or_initialize_domain
    @domain = Domain.find_or_initialize_by(domain: params[:id])
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
