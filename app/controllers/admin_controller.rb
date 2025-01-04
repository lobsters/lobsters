# rubocop:disable Rails/ApplicationController
class AdminController < ActionController::Base
  http_basic_authenticate_with \
    name: Rails.application.credentials.dig(:mission_control, :user),
    password: Rails.application.credentials.dig(:mission_control, :password)
end
# rubocop:enable Rails/ApplicationController
