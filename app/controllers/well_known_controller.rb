# typed: false

class WellKnownController < ApplicationController
  def apple_app_site_association
    render json: {
      webcredentials: {
        apps: [
          "6YP6RAX9V5.com.scamallsoftware.Pinchy"
        ]
      }
    }
  end
end
