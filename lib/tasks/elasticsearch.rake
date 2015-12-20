# require 'elasticsearch/rails/tasks/import'

# https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-rails
#
# bundle exec rake environment elasticsearch:import:model CLASS='Video' SCOPE='published'
#
# heroku run rake environment elasticsearch:import:model CLASS='Video'

def say_with_time(words)
  ActiveRecord::Migration.say_with_time("#{words}...") do
    yield
  end
end

namespace :elasticsearch do
  desc "creates new index for elasticsearch"

  task index: :environment do
    say_with_time "creating new index" do
      Story.__elasticsearch__.create_index! force: true
      Story.import
      Story.__elasticsearch__.refresh_index!
    end
  end
end
