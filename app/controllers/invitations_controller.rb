class InvitationsController < ApplicationController
  before_filter :require_logged_in_user,
    :except => [ :build, :create_by_request, :confirm_email ]

  def build
  end

  def index
    @invitation_requests = InvitationRequest.where(:is_verified => true)
  end

  def confirm_email
    if !(ir = InvitationRequest.find_by_code(params[:code].to_s))
      flash[:error] = "Invalid or expired invitation request"
      return redirect_to "/invitations/request"
    end

    ir.is_verified = true
    ir.save!

    flash[:success] = "Your invitiation request has been validated and " <<
      "will now be shown to other logged-in users."
    return redirect_to "/invitations/request"
  end

  def create
    i = Invitation.new
    i.user_id = @user.id
    i.email = params[:email]
    i.memo = params[:memo]

    begin
      if i.save
        i.send_email
        flash[:success] = "Successfully e-mailed invitation to " <<
          params[:email].to_s << "."
      else
        raise
      end
    rescue
      flash[:error] = "Could not send invitation, verify the e-mail " <<
        "address is valid."
    end

    if params[:return_home]
      return redirect_to "/"
    else
      return redirect_to "/settings"
    end
  end

  def create_by_request
    ir = InvitationRequest.new
    ir.name = params[:name]
    ir.email = params[:email]
    ir.memo = params[:memo]

    ir.ip_address = request.remote_ip

    if ir.save
      flash[:success] = "You have been e-mailed a confirmation to " <<
        params[:email].to_s << "."
      return redirect_to "/invitations/request"
    else
      render :action => :build
    end
  end

  def send_for_request
    if !(ir = InvitationRequest.find_by_code(params[:code].to_s))
      flash[:error] = "Invalid or expired invitation request"
      return redirect_to "/invitations"
    end

    if ir.save
      i = Invitation.new
      i.user_id = @user.id
      i.email = ir.email

      if i.save
        i.send_email
        ir.destroy
        flash[:success] = "Successfully e-mailed invitation to " <<
          ir.name.to_s << "."
      end

      return redirect_to "/invitations"
    else
      render :action => :build
    end
  end
end
