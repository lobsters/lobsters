# typed: false

class StoryImageController < ApplicationController
  CACHE_DIR = Rails.public_path.join("story_image/").to_s.freeze

  def show
    short_id = params[:short_id]

    s = Story.where(short_id: short_id).first!

    cached_image = File.join(CACHE_DIR, "#{File.basename(s.short_id)}.png")

    if File.exist?(cached_image)
      response.headers["Expires"] = 1.hour.from_now.httpdate
      send_file cached_image, type: "image/png", disposition: "inline"
    else
      CreateStoryCardJob.perform_later(s)
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
