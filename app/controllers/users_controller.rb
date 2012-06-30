class UsersController < ApplicationController
  def show
    @showing_user = User.find_by_username!(params[:id])

    @page_title = "User: #{@showing_user.username}"

  end
end
