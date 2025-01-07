class JobsModController < ApplicationController
  include Authenticatable

  before_action :require_logged_in_moderator
end
