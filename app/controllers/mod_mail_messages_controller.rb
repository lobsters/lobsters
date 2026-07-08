class ModMailMessagesController < ApplicationController
  before_action :require_logged_in_user

  def create
    # TODO use mod_mail short_id
    mod_mail = @user.mod_mails.find(params[:mod_mail_message][:mod_mail_id])
    @mod_mail_message = mod_mail.mod_mail_messages.new(mod_mail_message_params.merge({user: @user}))

    if @mod_mail_message.save
      NotifyModMailMessageJob.perform_later(@mod_mail_message)
      redirect_to @mod_mail_message.mod_mail, notice: "Your mod mail message has been sent."
    else
      redirect_to @mod_mail_message.mod_mail, notice: "Your mod mail message failed: #{@mod_mail_message.errors.full_messages}"
    end
  end

  private

  def mod_mail_message_params
    params.expect(mod_mail_message: [:mod_mail_id, :message])
  end
end
