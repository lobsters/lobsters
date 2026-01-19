# typed: false

class StoryImageController < ApplicationController
  def show
    short_id = params[:short_id]
    story = Story.where(short_id: short_id).first!
    image = StoryImage.new(story)

    if image.exists?
      response.headers["Expires"] = 1.hour.from_now.httpdate
      send_file image.path, type: "image/png", disposition: "inline"
    else
      lobsters_logo = Rails.public_path.join("touch-icon-144.png")
      if File.exist?(lobsters_logo)
        response.headers["Expires"] = 1.hour.from_now.httpdate
        send_file lobsters_logo, type: "image/png", disposition: "inline"
      else
        head :not_found
      end
    end
  end
end
