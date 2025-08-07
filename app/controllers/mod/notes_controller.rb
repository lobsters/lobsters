# typed: false

class Mod::NotesController < Mod::ModController
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
