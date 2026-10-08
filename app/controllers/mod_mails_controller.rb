class ModMailsController < ApplicationController
  before_action :require_logged_in_user

  def index
    @title = "ModMail"
    @mod_mails = @user.mod_mails.order(updated_at: :desc)
  end

  def show
    return redirect_to mod_mod_mail_path(params[:id]) if @user.is_moderator?

    @mod_mail = @user.mod_mails.find_by!(short_id: params.expect(:id))
    @mod_mail_message = ModMailMessage.new(user: @user, mod_mail: @mod_mail)
    @messages = @mod_mail.mod_mail_messages.order(:created_at)
  end
end
