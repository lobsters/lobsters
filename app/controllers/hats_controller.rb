# typed: false

class HatsController < ApplicationController
  before_action :require_logged_in_user, except: [:index]
  before_action :require_logged_in_moderator, except: [:build_request, :index, :create_request, :doff, :doff_by_user]
  before_action :show_title_h1
  before_action :find_hat, only: [:doff, :doff_by_user]
  before_action :only_hat_user_or_moderator, only: [:doff, :doff_by_user]

  def build_request
    @title = "Request a Hat"

    @hat_request = HatRequest.new
  end

  def index
    @title = "Hats"

    @hat_groups = {}

    Hat.active.includes(:user).find_each do |h|
      @hat_groups[h.hat] ||= []
      @hat_groups[h.hat].push h
    end
  end

  def create_request
    @hat_request = HatRequest.new
    @hat_request.user_id = @user.id
    @hat_request.hat = params[:hat_request][:hat]
    @hat_request.link = params[:hat_request][:link]
    @hat_request.comment = params[:hat_request][:comment]

    if @hat_request.save
      flash[:success] = "Successfully submitted hat request."
      return redirect_to "/hats"
    end

    render action: "build_request"
  end

  def requests_index
    @title = "Hat Requests"

    @hat_requests = HatRequest.all.includes(:user)
  end

  def approve_request
    @hat_request = HatRequest.find(params[:id])
    @hat_request.update!(params.require(:hat_request)
      .permit(:hat, :link, :reason).except(:reason))
    @hat_request.approve_by_user_for_reason!(@user, params[:hat_request][:reason])

    flash[:success] = "Successfully approved hat request."

    redirect_to "/hats/requests"
  end

  def reject_request
    @hat_request = HatRequest.find(params[:id])
    @hat_request.reject_by_user_for_reason!(@user, params[:hat_request][:reason])

    flash[:success] = "Successfully rejected hat request."

    redirect_to "/hats/requests"
  end

  def doff
    @title = "Doffing a Hat"
  end

  def doff_by_user
    if doff_with_reason(@hat, params[:reason])
      redirect_to @user
    else
      redirect_to doff_hat_path(@hat)
    end
  end

  private

  def doff_with_reason(hat, reason)
    if reason.present?
      hat.doff_by_user_with_reason(@user, reason)
      true
    else
      flash[:error] = "You must give a reason for the doffing."
      false
    end
  end

  def only_hat_user_or_moderator
    if @hat.user == @user || @user.is_moderator?
      true
    else
      redirect_to @user
    end
  end

  def find_hat
    if (@hat = Hat.where(id: params[:id]).first)
      return true
    end

    flash[:error] = "Could not find hat."
    redirect_to "/hats"
    false
  end
end
