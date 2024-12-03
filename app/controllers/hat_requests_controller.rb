# typed: false

class HatRequestsController < ApplicationController
  before_action :require_logged_in_user
  before_action :require_logged_in_moderator, only: [:approve, :reject]
  before_action :show_title_h1

  def new
    @title = "Request a Hat"
    @hat_request = HatRequest.new
    render :new
  end

  def create
    @hat_request = HatRequest.new
    @hat_request.user_id = @user.id
    @hat_request.hat = params[:hat_request][:hat]
    @hat_request.link = params[:hat_request][:link]
    @hat_request.comment = params[:hat_request][:comment]

    if @hat_request.save
      flash[:success] = "Successfully submitted hat request."
      return redirect_to "/hats"
    end

    render action: :new
  end

  def index
    @title = "Hat Requests"
    @hat_requests = HatRequest.all.includes(:user)
  end

  def approve
    @hat_request = HatRequest.find(params[:id])
    @hat_request.update!(params.require(:hat_request)
      .permit(:hat, :link, :reason).except(:reason))
    @hat_request.approve_by_user_for_reason!(@user, params[:hat_request][:reason])

    flash[:success] = "Successfully approved hat request."

    redirect_to hat_requests_path
  end

  def reject
    @hat_request = HatRequest.find(params[:id])
    @hat_request.reject_by_user_for_reason!(@user, params[:hat_request][:reason])

    flash[:success] = "Successfully rejected hat request."

    redirect_to hat_requests_path
  end
end
