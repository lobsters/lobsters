# typed: false

class OriginsController < ApplicationController
  before_action :require_logged_in_moderator, only: [:edit, :update]
  before_action :find_or_initialize_origin, only: [:edit, :update]

  def edit
  end

  def update
    @origin.assign_attributes(origin_params)
    if params[:commit] == "Ban"
      @origin.ban_by_user_for_reason! @user, origin_params[:banned_reason]
    elsif params[:commit] == "Unban"
      @origin.unban_by_user_for_reason! @user, origin_params[:banned_reason]
    end
    if @origin.save
      flash[:success] = "Origin edited"
      redirect_to origin_path(@origin)
    else
      render :edit
    end
  end

  def for_domain
    @domain = Domain.find_by!(domain: params[:id])
    @origins = @domain.origins.order(identifier: :asc)
  end

  private

  def origin_params
    params.require(:origin).permit(:banned_reason)
  end

  def find_or_initialize_origin
    @origin = Origin.find_by! identifier: params[:identifier]
  end

  def caption_of_button(origin)
    if origin.new_record?
      "Create and Ban"
    else
      origin.banned_at ? "Unban" : "Ban"
    end
  end

  helper_method :caption_of_button
end
