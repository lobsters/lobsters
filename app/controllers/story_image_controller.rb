# typed: false

class StoryImageController < ApplicationController
  CACHE_DIR = Rails.public_path.join("story_image/").to_s.freeze

  def show
    short_id = params[:short_id]

    s = Story.where(short_id: short_id).first!

    story_image = s.generated_image

    if story_image.present?
      FileUtils.mkdir_p(CACHE_DIR)

      File.open("#{CACHE_DIR}/.#{s.short_id}.png", "wb+") do |f|
        f.write story_image
      end

      File.rename("#{CACHE_DIR}/.#{s.short_id}.png", "#{CACHE_DIR}/#{s.short_id}.png")
    else
      lobsters_logo = Rails.public_path.join("touch-icon-144.png")
      if File.exist?(lobsters_logo)
        story_image = File.read(lobsters_logo)
      else
        head :not_found
        return
      end
    end

    response.headers["Expires"] = 1.hour.from_now.httpdate
    send_data story_image, type: "image/png", disposition: "inline"
  end
end
