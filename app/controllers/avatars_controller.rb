class AvatarsController < ApplicationController
  ALLOWED_SIZES = [ 16, 32, 100, 200 ]

  CACHE_DIR = "#{Rails.root}/public/avatars/"

  def show
    username, size = params[:username_size].to_s.scan(/\A(.+)-(\d+)\z/).first
    size = size.to_i

    if !ALLOWED_SIZES.include?(size)
      raise ActionController::RoutingError.new("invalid size")
    end

    if !username.match(User::VALID_USERNAME)
      raise ActionController::RoutingError.new("invalid user name")
    end

    u = User.where(:username => username).first!

    if !(av = u.fetched_avatar(size))
      raise ActionController::RoutingError.new("failed fetching avatar")
    end

    if !Dir.exists?(CACHE_DIR)
      Dir.mkdir(CACHE_DIR)
    end

    File.open("#{CACHE_DIR}/.#{u.username}-#{size}.png", "wb+") do |f|
      f.write av
    end

    File.rename("#{CACHE_DIR}/.#{u.username}-#{size}.png",
      "#{CACHE_DIR}/#{u.username}-#{size}.png")

    response.headers["Expires"] = 1.hour.from_now.httpdate
    send_data av, :type => "image/png", :disposition => "inline"
  end
end
