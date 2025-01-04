# rubocop:disable Rails/ApplicationController
class AdminController < ActionController::Base
  http_basic_authenticate_with \
    name: Rails.application.credentials.dig(:mission_control, :user) || "test_user",
    password: Rails.application.credentials.dig(:mission_control, :password) || "test_password"
end
# rubocop:enable Rails/ApplicationController
