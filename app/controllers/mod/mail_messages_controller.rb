class Mod::MailMessagesController < Mod::ModController
  # POST /mod_mail_messages
  def create
    @mod_mail_message = ModMailMessage.new(mod_mail_message_params.merge({user: @user}))

    if @mod_mail_message.save
      NotifyModMailMessageJob.perform_later(@mod_mail_message)
      redirect_to mod_mod_mail_path(@mod_mail_message.mod_mail), notice: "Your mod mail message has been sent."
    else
      redirect_to mod_mod_mail_path(@mod_mail_message.mod_mail), notice: "Your mod mail message failed: #{@mod_mail_message.errors.full_messages}"
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def mod_mail_message_params
    params.expect(mod_mail_message: [:mod_mail_id, :message])
  end
end
