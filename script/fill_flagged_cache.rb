#!/usr/bin/env ruby

require File.expand_path("../../config/environment", __FILE__)

# fills the cache - used by app/views/users/show.html.erb for mods

FlaggedCommenters.new("1m").commenters
