# typed: false

class Mod::OriginsBanController < Mod::ModController
  before_action :find_or_initialize_origin

  def create_and_ban
    @origin = Origin.new(identifier: params[:identifier])
    Origin.transaction do
      @origin.domain = Domain.where(domain: @origin.identifier.split("/").first).first_or_create!
      @origin.ban_by_user_for_reason!(@user, origin_params[:banned_reason])
    end
    flash[:success] = "Origin created and banned"
    redirect_to origin_path(@origin)
  rescue ActiveRecord::RecordInvalid
    render "mod/origins/edit"
  end

  def update
    if origin_params[:banned_reason].present?
      if @origin.banned?
        @origin.unban_by_user_for_reason!(@user, origin_params[:banned_reason])
      else
        @origin.ban_by_user_for_reason!(@user, origin_params[:banned_reason])
      end
      flash[:success] = "Origin updated."
      redirect_to origin_path(@origin)
    else
      flash.now[:error] = "Reason required for the modlog."
      render "mod/origins/edit"
    end
  end

  private

  def origin_params
    params.require(:origin).permit(:banned_reason)
  end

  def find_or_initialize_origin
    @origin = Origin.find_or_initialize_by identifier: params[:identifier]
  end
end
