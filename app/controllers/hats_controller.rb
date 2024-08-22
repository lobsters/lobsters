# typed: false

class HatsController < ApplicationController
  before_action :require_logged_in_user, except: [:index]
  before_action :require_logged_in_moderator, except: [:build_request, :index, :create_request, :doff, :doff_by_user]
  before_action :show_title_h1
  before_action :find_hat!, only: [:doff, :doff_by_user, :edit, :edit_in_place, :doff_and_create_new]
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
    if params[:reason].blank?
      flash[:error] = "You must give a reason for the doffing."
      return redirect_to doff_hat_path(@hat)
    end

    @hat.doff_by_user_with_reason(@user, params[:reason])
    redirect_to @user
  end

  def edit
    @title = "Edit a Hat"
  end

  def edit_in_place
    old_hat = @hat.hat
    new_hat = params[:hat][:hat]

    if @hat.update(hat: new_hat)
      m = Moderation.new
      m.user_id = @hat.user_id
      m.moderator_user_id = @hat.user_id
      m.action = "Renamed hat \"#{old_hat}\" to \"#{new_hat}\""
      m.save!

      redirect_to hats_url
    else
      flash[:error] = @hat.errors.full_messages.join(", ")
      redirect_to edit_hat_path(@hat)
    end
  end

  def doff_and_create_new
    new_hat = params[:hat][:hat]

    replaced_hat = @hat.dup
    replaced_hat.hat = new_hat
    replaced_hat.doffed_at = nil

    if replaced_hat.save
      @hat.doff_by_user_with_reason(@user, "To replace with \"#{new_hat}\"")

      redirect_to hats_url
    else
      flash[:error] = replaced_hat.errors.full_messages.join(", ")
      redirect_to edit_hat_path(@hat)
    end
  end

  private

  def only_hat_user_or_moderator
    if @hat.user == @user || @user.is_moderator?
      true
    else
      redirect_to @user
    end
  end

  def find_hat!
    @hat = @user.is_moderator? ? Hat.find(params[:id]) : @user.hats.find(params[:id])
  end
end
