class InvitationsController < ApplicationController
  before_filter :require_logged_in_user

  def create
    i = Invitation.new
    i.user_id = @user.id
    i.email = params[:email]
    i.memo = params[:memo]

    unless User.find_by_email(params[:email])
      if i.save
        i.send_email
        flash[:success] = "Successfully e-mailed invitation to " <<
          params[:email].to_s << "."
      else
        flash[:error] = "Could not send invitation, verify the e-mail " <<
          "address is valid."
      end
    else
      flash[:error] = "#{params[:email]} has already joined Lobsters"
    end

    return redirect_to "/settings"
  end
end
