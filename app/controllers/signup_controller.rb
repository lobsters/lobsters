class SignupController < ApplicationController
  before_filter :require_logged_in_user, :only => :invite

  def index
    if @user
      flash[:error] = "You are already signed up."
      return redirect_to "/"
    end

    @title = "Signup"
  end

  def invited
    if @user
      flash[:error] = "You are already signed up."
      return redirect_to "/"
    end

    if !(@invitation = Invitation.find_by_code(params[:invitation_code].to_s))
      flash[:error] = "Invalid or expired invitation"
      return redirect_to "/signup"
    end

    @title = "Signup"

    @new_user = User.new
    @new_user.email = @invitation.email

    render :action => "invited"
  end

  def signup
    if !(@invitation = Invitation.find_by_code(params[:invitation_code].to_s))
      flash[:error] = "Invalid or expired invitation."
      return redirect_to "/signup"
    end

    @title = "Signup"

    @new_user = User.new(params[:user])
    @new_user.invited_by_user_id = @invitation.user_id

    if @new_user.save
      @invitation.destroy
      session[:u] = @new_user.session_token
      flash[:success] = "Welcome to #{Rails.application.name}, " <<
        "#{@new_user.username}!"

      Countinual.count!("#{Rails.application.shortname}.users.created", "+1")

      return redirect_to "/signup/invite"
    else
      render :action => "invited"
    end
  end
end
