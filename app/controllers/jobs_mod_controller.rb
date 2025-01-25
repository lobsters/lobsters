# rubocop:disable Rails/ApplicationController
class JobsModController < ActionController::Base
  include Authenticatable

  before_action :require_logged_in_moderator
end
# rubocop:enable Rails/ApplicationController
