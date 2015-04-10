class UsersController < ApplicationController
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
      @users = User.where("is_admin = 1 OR is_moderator = 1").
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
end
