class SignupController < ApplicationController
  before_action :require_logged_in_user, :only => :invite
  before_action :check_for_read_only_mode

  def index
    if @user
      flash[:error] = "You are already signed up."
      return redirect_to "/"
    end
    if Rails.application.open_signups?
      redirect_to action: :invited, invitation_code: 'open' and return
    end
    @title = "Signup"
  end

  def invite
    @title = "Pass Along an Invitation"
  end

  def invited
    if @user
      flash[:error] = "You are already signed up."
      return redirect_to "/"
    end

    if not Rails.application.open_signups?
      if !(@invitation = Invitation.where(:code => params[:invitation_code].to_s).first)
        flash[:error] = "Invalid or expired invitation"
        return redirect_to "/signup"
      end
    end

    @title = "Signup"

    @new_user = User.new

    if not Rails.application.open_signups?
      @new_user.email = @invitation.email
    end

    render :action => "invited"
  end

  def signup
    if not Rails.application.open_signups?
      if !(@invitation = Invitation.where(:code => params[:invitation_code].to_s).first)
        flash[:error] = "Invalid or expired invitation."
        return redirect_to "/signup"
      end
    end

    @title = "Signup"

    @new_user = User.new(user_params)

    if not Rails.application.open_signups?
      @new_user.invited_by_user_id = @invitation.user_id
    end

    if @new_user.save
      if not Rails.application.open_signups?
        @invitation.destroy
      end
      session[:u] = @new_user.session_token
      flash[:success] = "Welcome to #{Rails.application.name}, " <<
        "#{@new_user.username}!"

      return redirect_to "/signup/invite"
    else
      render :action => "invited"
    end
  end

private
  def user_params
    params.require(:user).permit(
      :username, :email, :password, :password_confirmation, :about,
    )
  end
end
