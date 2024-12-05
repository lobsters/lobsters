class Mod::ModeratorController < ApplicationController
  before_action :require_logged_in_moderator
end
