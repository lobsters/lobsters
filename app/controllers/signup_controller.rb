class SignupController < ApplicationController
  def index
    @page_title = "Signup"
    @new_user = User.new
  end

  def signup
    @new_user = User.new(params[:user])

    if @new_user.save
      session[:u] = @new_user.session_hash
      return redirect_to "/"
    else
      render :action => "index"
    end
  end
end
