class Mod::ReparentsController < Mod::ModeratorController
  before_action :require_logged_in_admin
  before_action :load_user

  def new
  end

  def create
    if params[:reason].blank?
      return redirect_to new_mod_reparent_path({}, id: @reparent_user), flash: {error: "Reason can't be blank."}
    end

    User.transaction do
      ModNote.record_reparent!(@reparent_user, @user, params[:reason])
      @reparent_user.invited_by_user = @user
      @reparent_user.save!
      Moderation.create!({
        moderator: @user,
        user: @reparent_user,
        action: "Reparented user to be invited by #{@user.username}",
        reason: params[:reason]
      })
    end
    Rails.cache.delete("users_tree_#{User.last.id}") # UsersController#tree

    redirect_to user_path(@reparent_user), flash: {success: "User been has reparented to you."}
  end

  private

  def load_user
    params.require(:id)
    @reparent_user = User.find_by! username: params[:id]
  end
end
