class Mod::MailsController < Mod::ModController
  before_action :set_mod_mail, only: %i[show edit update]
  before_action :new_mod_mail, only: %i[create]
  before_action :parse_references_and_recipients, only: %i[update create]

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
    if @mod_mail.save
      redirect_to mod_mod_mail_path(@mod_mail), notice: "Mod mail was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /mod_mails/1
  def update
    if @mod_mail.update(mod_mail_params)
      redirect_to mod_mod_mail_path(@mod_mail), notice: "Mod mail was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_mod_mail
    @mod_mail = ModMail.find_by(short_id: params.expect(:id))
  end

  def new_mod_mail
    @mod_mail = ModMail.new(mod_mail_params)
  end

  # Convert space-separated short IDs into references.
  def parse_references_and_recipients
    @mod_mail.recipients = User.where(username: params.dig("mod_mail", "recipient_usernames")&.split(" "))
    @mod_mail.comment_references = Comment.where(short_id: params.dig("mod_mail", "comment_reference_short_ids")&.split(" "))
    @mod_mail.story_references = Story.where(short_id: params.dig("mod_mail", "story_reference_short_ids")&.split(" "))
  end

  # Only allow a list of trusted parameters through.
  def mod_mail_params
    params.expect(mod_mail: [:subject, :recipients, :references])
  end
end
