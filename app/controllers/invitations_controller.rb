# typed: false

class InvitationsController < ApplicationController
  before_action :require_logged_in_user, except: [:build, :create_by_request, :confirm_email]
  before_action :show_title_h1

  def build
    @title = "Request an Invitation"
    if Rails.application.allow_invitation_requests?
      @invitation_request = InvitationRequest.new
    else
      flash[:error] = "Public invitation requests are not allowed."
      redirect_to "/login"
    end
  end

  def index
    @title = "Requested Invitations"
    if !@user.can_see_invitation_requests?
      flash[:error] = "Your account is not permitted to view invitation requests."
      return redirect_to "/"
    end

    @invitation_requests = InvitationRequest.where(is_verified: true)
  end

  def confirm_email
    if !(ir = InvitationRequest.where(code: params[:code].to_s).first)
      flash[:error] = "Invalid or expired invitation request"
      return redirect_to "/invitations/request"
    end

    ir.is_verified = true
    ir.save!

    flash[:success] = "Your invitation request has been validated and " \
      "will now be shown to other logged-in users."
    redirect_to "/invitations/request"
  end

  def create
    if !@user.can_invite?
      flash[:error] = "Your account cannot send invitations"
      redirect_to "/settings"
      return
    end

    i = Invitation.new
    i.user_id = @user.id
    i.email = params[:email].delete_prefix("mailto:").strip
    i.memo = params[:memo]

    begin
      i.save!
      i.send_email
      flash[:success] = "Successfully e-mailed invitation to " <<
        params[:email].to_s << "."
    rescue => e
      # Rails.logger.error "Error creating invitation for #{params[:email]}: #{e.message}"
      flash[:error] = "Could not send invitation, verify the e-mail " \
        "address is valid."
    end

    if params[:return_home]
      redirect_to "/"
    else
      redirect_to "/settings"
    end
  end

  def create_by_request
    if Rails.application.allow_invitation_requests?
      @invitation_request = InvitationRequest.new(
        params.require(:invitation_request).permit(:name, :email, :memo)
      )

      @invitation_request.ip_address = request.remote_ip

      if @invitation_request.save
        flash[:success] = "You have been e-mailed a confirmation to " <<
          params[:invitation_request][:email].to_s << "."
        redirect_to "/invitations/request"
      else
        render action: :build
      end
    else
      redirect_to "/login"
    end
  end

  def send_for_request
    if !@user.can_see_invitation_requests?
      flash[:error] = "Your account is not permitted to view invitation " \
        "requests."
      return redirect_to "/"
    end

    if !(ir = InvitationRequest.where(code: params[:code].to_s).first)
      flash[:error] = "Invalid or expired invitation request"
      return redirect_to "/invitations"
    end

    i = Invitation.new
    i.user_id = @user.id
    i.email = ir.email
    i.save!
    i.send_email
    ir.destroy!
    flash[:success] = "Successfully e-mailed invitation to " <<
      ir.name.to_s << "."

    # Rails.logger.info "[u#{@user.id}] sent invitiation for request " << ir.inspect

    redirect_to "/invitations"
  end

  def delete_request
    if !@user.can_see_invitation_requests?
      return redirect_to "/invitations"
    end

    if !(ir = InvitationRequest.where(code: params[:code].to_s).first)
      flash[:error] = "Invalid or expired invitation request"
      return redirect_to "/invitations"
    end

    ir.destroy!
    flash[:success] = "Successfully deleted invitation request from " <<
      ir.name.to_s << "."

    # Rails.logger.info "[u#{@user.id}] deleted invitation request from #{ir.inspect}"

    redirect_to "/invitations"
  end
end
