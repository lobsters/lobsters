# typed: false

class ModNotesController < ModController
  before_action :require_logged_in_moderator

  def index
    @title = "Mod Notes"
    @username = params[:username]
    query = ModNote.order(created_at: :desc).includes(:moderator, :user)
    if (@username = params[:username])
      if (user = User.find_by(username: @username))
        @title = "#{@username} Mod Notes"
        @notes = query.where(user: user)
      else
        @notes = []
        flash[:error] = "User not found"
      end
    else
      @notes = period(query)
    end
  end

  def create
    @title = "Create Mod Note"
    @mod_note = ModNote.new(mod_note_params)
    @mod_note.moderator = @user
    if @mod_note.save
      redirect_to user_path(@mod_note.user), success: "Noted"
    else
      # This is bad and needs to change if note ever has non-trivial validation
      redirect_to user_path(@mod_note.user),
        error: "Invalid note and Peter half-assed the error handling"
    end
  end

  private

  def mod_note_params
    params.require(:mod_note).permit(:username, :note)
  end
end
