class InvitationsController < ApplicationController
  before_filter :require_logged_in_user,
    :except => [ :build, :create_by_request, :confirm_email ]

  def build
    if Rails.application.allow_invitation_requests?
      @invitation_request = InvitationRequest.new
    else
      flash[:error] = I18n.t 'controllers.invitations_controller.flashpublicinvitnotallowed'
      return redirect_to "/login"
    end
  end

  def index
    @invitation_requests = InvitationRequest.where(:is_verified => true)
  end

  def confirm_email
    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = I18n.t 'controllers.invitations_controller.flashrequestconfirmation'
      return redirect_to "/invitations/request"
    end

    ir.is_verified = true
    ir.save!

    flash[:success] = I18n.t 'controllers.invitations_controller.flashsuccessinvitrequest'
    return redirect_to "/invitations/request"
  end

  def create
    if !@user.can_invite? || !Rails.application.allow_invitation_sendings?
      flash[:error] = I18n.t 'controllers.invitations_controller.flashaccountnotinvit'
      redirect_to "/settings"
      return
    end

    i = Invitation.new
    i.user_id = @user.id
    i.email = params[:email]
    i.memo = params[:memo]

    begin
      i.save!
      i.send_email
      flash[:success] = I18n.t 'controllers.invitations_controller.flashsuccessinvit', :guest => "#{params[:email].to_s}"
    rescue
      flash[:error] = I18n.t 'controllers.invitations_controller.flasherrorssinvit'
    end

    if params[:return_home]
      return redirect_to "/"
    else
      return redirect_to "/settings"
    end
  end

  def create_by_request
    if Rails.application.allow_invitation_requests?
      @invitation_request = InvitationRequest.new(
        params.require(:invitation_request).permit(:name, :email, :memo))

      @invitation_request.ip_address = request.remote_ip

      if @invitation_request.save
        flash[:success] = I18n.t 'controllers.invitations_controller.flashrequestconfirmation', :email => "#{params[:invitation_request][:email].to_s}"
        return redirect_to "/invitations/request"
      else
        render :action => :build
      end
    else
      return redirect_to "/login"
    end
  end

  def send_for_request
    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = I18n.t 'controllers.invitations_controller.flashinvalidinvitation'
      return redirect_to "/invitations"
    end

    i = Invitation.new
    i.user_id = @user.id
    i.email = ir.email

    i.save!
    i.send_email
    ir.destroy!
    flash[:success] = I18n.t 'controllers.invitations_controller.flashsuccessinvit', :guest => "#{ir.name.to_s}"
    return redirect_to "/invitations"
  end

  def delete_request
    if !@user.is_moderator?
      return redirect_to "/invitations"
    end

    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = I18n.t 'controllers.invitations_controller.flashrequestconfirmation'
      return redirect_to "/invitations"
    end

    ir.destroy!
    flash[:success] = I18n.t 'controllers.invitations_controller.flashsuccessdeleteinvit', :name => "#{ir.name.to_s}"
    return redirect_to "/invitations"
  end
end
