# typed: false

class AvatarsController < ApplicationController
  before_action :require_logged_in_user, only: [:expire]

  ALLOWED_SIZES = [16, 32, 100, 200].freeze

  CACHE_DIR = Rails.public_path.join("avatars/").to_s.freeze

  def expire
    expired = @user.expire_avatar!
    flash[:success] = "Your avatar cache has been purged of #{"file".pluralize(expired)}"
    redirect_to "/settings"
  end

  def show
    username, size = params[:username_size].to_s.scan(/\A(.+)-(\d+)\z/).first
    size = size.to_i

    if !ALLOWED_SIZES.include?(size)
      raise ActionController::RoutingError.new("invalid size")
    end

    if !username.match(User::VALID_USERNAME)
      raise ActionController::RoutingError.new("invalid user name")
    end

    u = User.where(username: username).first!

    if !(av = u.fetched_avatar(size))
      raise ActionController::RoutingError.new("failed fetching avatar")
    end

    # the hatchbox pre-build script symlinks this to a shared folder but sister sites will most
    # likely have a single repo they update rather than replace
    if !File.exist?(CACHE_DIR) && !Dir.exist?(CACHE_DIR)
      Dir.mkdir(CACHE_DIR)
    end

    File.open("#{CACHE_DIR}/.#{u.username}-#{size}.png", "wb+") do |f|
      f.write av
    end

    File.rename("#{CACHE_DIR}/.#{u.username}-#{size}.png", "#{CACHE_DIR}/#{u.username}-#{size}.png")

    response.headers["Expires"] = 1.hour.from_now.httpdate
    send_data av, type: content_type_for(av), disposition: "inline"
  end

  private

  def content_type_for(data)
    data.start_with?("\xFF\xD8\xFF".b) ? "image/jpeg" : "image/png"
  end
end
