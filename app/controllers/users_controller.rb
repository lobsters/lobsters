class UsersController < ApplicationController
  def show
    @showing_user = User.where(:username => params[:id]).first!
    @title = "User #{@showing_user.username}"
  end

  def tree
    @title = "Users"

    users = User.order("id DESC").to_a

    @user_count = users.length
    @users_by_parent = users.group_by(&:invited_by_user_id)
  end

  def invite
    @title = "Pass Along an Invitation"
  end
end
