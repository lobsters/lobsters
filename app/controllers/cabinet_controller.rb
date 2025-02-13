class CabinetController < ApplicationController
  def index
    render
    puts "controller after render @user - #{@user}"
  end
end
