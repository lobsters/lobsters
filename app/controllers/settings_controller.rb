class SettingsController < ApplicationController
  before_filter :require_logged_in_user

  def index
    @title = "Account Settings"

    @edit_user = @user.dup
  end

  def update
    @edit_user = @user.clone

    if @edit_user.update_attributes(params[:user])
      flash.now[:success] = "Successfully updated settings."
      @user = @edit_user
    end

    render :action => "index"
  end
end
