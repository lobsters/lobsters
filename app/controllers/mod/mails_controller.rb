class Mod::MailsController < Mod::ModController
  before_action :set_mod_mail, only: %i[ show edit update]
  before_action :require_logged_in_moderator_or_recipient, only: :show
  skip_before_action :require_logged_in_moderator, only: :show

  # GET /mod_mails
  def index
    @mod_mails = ModMail.all
  end

  # GET /mod_mails/1
  def show
    @mod_mail_message = ModMailMessage.new(user: @user, mod_mail: @mod_mail)
    @messages = @mod_mail.mod_mail_messages.order(:created_at)
  end

  # GET /mod_mails/new
  def new
    @mod_mail = ModMail.new
  end

  # GET /mod_mails/1/edit
  def edit
  end

  # POST /mod_mails
  def create
    @mod_mail = ModMail.new(mod_mail_params)
    @mod_mail.recipients = User.where(username: params["mod_mail"]["recipient_usernames"].split(' ')) if params["mod_mail"]["recipient_usernames"].present?

    if @mod_mail.save
      redirect_to @mod_mail, notice: "Mod mail was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /mod_mails/1
  def update
    @mod_mail.recipients = User.where(username: params["mod_mail"]["recipient_usernames"].split(' ')) if params["mod_mail"]["recipient_usernames"].present?
    if @mod_mail.update(mod_mail_params)
      redirect_to @mod_mail, notice: "Mod mail was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mod_mail
      @mod_mail = ModMail.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def mod_mail_params
      params.expect(mod_mail: [:subject, :recipients, :references])
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
