class Mod::MailMessagesController < Mod::ModController
  before_action :require_logged_in_moderator_or_recipient, only: :create
  skip_before_action :require_logged_in_moderator, only: :create

  # POST /mod_mail_messages
  def create
    @mod_mail_message = ModMailMessage.new(mod_mail_message_params.merge({ user: @user }))

    if @mod_mail_message.save
      redirect_to @mod_mail_message.mod_mail, notice: "Mod mail message was successfully created."
    else
      redirect_to @mod_mail_message.mod_mail, notice: "Your mod mail message failed: #{@mod_mail_message.errors.full_messages}"
    end
  end

  private
    # Only allow a list of trusted parameters through.
    def mod_mail_message_params
      params.expect(mod_mail_message: [ :mod_mail_id, :message ])
    end

    def require_logged_in_moderator_or_recipient
      require_logged_in_user

      if @user.is_moderator? || @mod_mail.recipients.include?(@user)
        true
      else
        flash[:error] = "You are not authorized to access that resource."
        redirect_to "/"
      end
    end
end
