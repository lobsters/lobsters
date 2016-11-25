class UsersController < ApplicationController
  before_filter :require_logged_in_moderator, :only => [ :enable_invitation,
                                                         :disable_invitation,
                                                         :ban, :unban ]

  def show
    @showing_user = User.where(:username => params[:username]).first!
    @title = "User #{@showing_user.username}"

    respond_to do |format|
      format.html { render :action => "show" }
      format.json { render :json => @showing_user }
    end
  end

  def tree
    @title = "Users"

    if params[:by].to_s == "karma"
      @users = User.order("karma DESC, id ASC").to_a
      @user_count = @users.length
      @title << " By Karma"
      render :action => "list"
    elsif params[:moderators]
      @users = User.where("is_admin = ? OR is_moderator = ?", true, true).
        order("id ASC").to_a
      @user_count = @users.length
      @title = "Moderators and Administrators"
      render :action => "list"
    else
      users = User.order("id DESC").to_a
      @user_count = users.length
      @users_by_parent = users.group_by(&:invited_by_user_id)
      @newest = User.order("id DESC").limit(10)
    end
  end

  def invite
    @title = "Pass Along an Invitation"
  end

  def disable_invitation
    target = User.where(:username => params[:username]).first
    if !target
      flash[:error] = "Invalid user."
      redirect_to "/"
    else
      target.disable_invite_by_user_for_reason!(@user, params[:reason])

      flash[:success] = "User has had invite capability disabled."
      redirect_to user_path(:user => target.username)
    end
  end

  def enable_invitation
    target = User.where(:username => params[:username]).first
    if !target
      flash[:error] = "Invalid user."
      redirect_to "/"
    else
      target.enable_invite_by_user!(@user)

      flash[:success] = "User has had invite capability enabled."
      redirect_to user_path(:user => target.username)
    end
  end

  def ban
    buser = User.where(:username => params[:username]).first
    if !buser
      flash[:error] = "Invalid user."
      return redirect_to "/"
    end

    if !params[:reason].present?
      flash[:error] = "You must give a reason for the ban."
      return redirect_to user_path(:user => buser.username)
    end

    buser.ban_by_user_for_reason!(@user, params[:reason])

    flash[:success] = "User has been banned."
    return redirect_to user_path(:user => buser.username)
  end

  def unban
    buser = User.where(:username => params[:username]).first
    if !buser
      flash[:error] = "Invalid user."
      return redirect_to "/"
    end

    buser.unban_by_user!(@user)

    flash[:success] = "User has been unbanned."
    return redirect_to user_path(:user => buser.username)
  end

  def block
    user_to_be_blocked = User.where(username: params.require(:username)).first

    if user_to_be_blocked
      @user.privately_block user_to_be_blocked
      flash[:success] = "User has been blocked"
      redirect_to :back
    else
      flash[:error] = "Invalid user"
      redirect_to :back
    end
  end

  def unblock
    user_to_be_unblocked = User.where(username: params.require(:username)).first

    if user_to_be_unblocked
      @user.unblock user_to_be_unblocked
      flash[:success] = "User has been unblocked"
      redirect_to :back
    else
      flash[:error] = "Invalid user"
      redirect_to :back
    end
  end
end
