# typed: false

class SignupController < ApplicationController
  before_action :require_logged_in_user, :check_new_users, :check_can_invite, only: :invite
  before_action :check_for_read_only_mode, :show_title_h1

  def index
    @title = "Create an Account"
    if @user
      flash[:error] = "You are already signed up."
      return redirect_to "/"
    end
    if Rails.application.open_signups?
      redirect_to action: :invited, invitation_code: "open" and return
    end
  end

  def invite
    @title = "Pass Along an Invitation"
  end

  def invited
    @title = "Create an Account"

    if @user
      flash[:error] = "You are already signed up."
      ModNote.tattle_on_invited(@user, params[:invitation_code])
      return redirect_to "/"
    end

    if !Rails.application.open_signups?
      if !(@invitation = Invitation.unused.where(code: params[:invitation_code].to_s).first)
        flash[:error] = "Invalid or expired invitation"
        return redirect_to "/signup"
      end
    end

    @title = "Signup"

    @new_user = User.new

    if !Rails.application.open_signups?
      @new_user.email = @invitation.email
    end
  end

  def signup
    if !Rails.application.open_signups?
      if !(@invitation = Invitation.unused.where(code: params[:invitation_code].to_s).first)
        flash[:error] = "Invalid or expired invitation."
        return redirect_to "/signup"
      end
    end

    @title = "Signup"

    @new_user = User.new(user_params)

    if !Rails.application.open_signups?
      @new_user.invited_by_user_id = @invitation.user_id
    end

    if @new_user.save
      @invitation&.update!(used_at: Time.current, new_user: @new_user)
      session[:u] = @new_user.session_token
      flash[:success] = "Welcome to #{Rails.application.name}, " \
        "#{@new_user.username}!"

      if Rails.application.allow_new_users_to_invite?
        redirect_to signup_invite_path
      else
        redirect_to root_path
      end
    else
      render action: "invited"
    end
  end

  private

  def check_new_users
    if !Rails.application.allow_new_users_to_invite? && @user.is_new?
      redirect_to root_path, flash: {error: "New users cannot send invites"}
    end
  end

  def check_can_invite
    if !@user.can_invite?
      redirect_to root_path, flash: {error: "You can't send invites"}
    end
  end

  def user_params
    params.require(:user).permit(
      :username, :email, :password, :password_confirmation, :about
    )
  end
end
