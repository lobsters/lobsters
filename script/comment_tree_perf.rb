#!/usr/bin/env ruby

# to use:
# change force_ssl to false in config/environments/production.rb
# SECRET_KEY_BASE=asdf rails server -e production -p 3000
# be ruby script/comment_tree_perf.rb > [implementation].csv
#
# assumes a local server is running in prod mode with prod data

APP_PATH = File.expand_path('../../config/application', __FILE__)
require File.expand_path('../../config/boot', __FILE__)
require APP_PATH
Rails.application.require_environment!

require 'benchmark-perf'
Rails.cache.clear

puts "short_id,comments_count,avg,stdev,dt"

Story.where('comments_count > 0').find_each(batch_size: 100) do |story|
  # no warmup because the db difference on fetches is ~50%
  # and we render old stories not in cache all day
  result = Benchmark::Perf.cpu(warmup: 0, repeat: 10) do
    `curl -qs http://localhost:3000/s/#{story.short_id} -o /dev/null`
  end

  puts "#{story.short_id},#{story.comments_count},#{result.avg},#{result.stdev},#{result.dt}"
end
