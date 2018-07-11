class ModNotesController < ModController
  before_action :require_logged_in_moderator

  def index
    @notes = period(ModNote.includes(:moderator, :user).all)
  end
end
