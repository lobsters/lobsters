#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../config/application', __FILE__)
require File.expand_path('../../config/boot', __FILE__)
require APP_PATH
Rails.application.require_environment!

# fills the cache - used by app/views/users/show.html.erb for mods

FlaggedCommenters.new('1m').commenters
