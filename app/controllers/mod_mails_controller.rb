class ModMailsController < ApplicationController
  before_action :set_mod_mail, only: :show
  before_action :require_logged_in_user
  before_action :require_recipient_or_mod

  # GET /mod_mails/1
  def show
    @mod_mail_message = ModMailMessage.new(user: @user, mod_mail: @mod_mail)
    @messages = @mod_mail.mod_mail_messages.order(:created_at)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_mod_mail
    @mod_mail = ModMail.find_by(short_id: params.expect(:id))
  end

  def require_recipient_or_mod
    unless @mod_mail.recipients.include?(@user) || @user.is_moderator?
      redirect_to :root, error: "You are not authorized to access that resource."
    end
  end
end
