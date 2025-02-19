class CabinetController < ApplicationController
  def index
    render
    Rails.logger.debug { "controller after render @user - #{@user}" }
  end
end
