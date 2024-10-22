# typed: false

class AvatarsController < ApplicationController
  before_action :require_logged_in_user, only: [:destroy]

  def destroy
    Prosopite.pause # ActiveStorage has a 1+n query deleting attachments
    @user.avatar.purge
    Prosopite.resume
    render layout: false, plain: "Avatar deleted", content_type: "text/plain"
  end
end
