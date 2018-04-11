class HatsController < ApplicationController
  before_action :require_logged_in_user, :except => [:index]
  before_action :require_logged_in_moderator, :except => [:build_request, :index, :create_request]

  def build_request
    @title = "Request a Hat"

    @hat_request = HatRequest.new
  end

  def index
    @title = "Hats"

    @hat_groups = {}

    Hat.all.includes(:user).each do |h|
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

    render :action => "build_request"
  end

  def requests_index
    @title = "Hat Requests"

    @hat_requests = HatRequest.all.includes(:user)
  end

  def approve_request
    @hat_request = HatRequest.find(params[:id])
    @hat_request.update!(params.require(:hat_request)
      .permit(:hat, :link))
    @hat_request.approve_by_user!(@user)

    flash[:success] = "Successfully approved hat request."

    return redirect_to "/hats/requests"
  end

  def reject_request
    @hat_request = HatRequest.find(params[:id])
    @hat_request.reject_by_user_for_reason!(@user, params[:hat_request][:rejection_comment])

    flash[:success] = "Successfully rejected hat request."

    return redirect_to "/hats/requests"
  end
end
