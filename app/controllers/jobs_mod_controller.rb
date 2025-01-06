class JobsModController < ActionController::Base
  include Authenticatable

  before_action :require_logged_in_moderator
end
