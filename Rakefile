# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

if Rails.env.development? || Rails.env.test?
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end

Lobsters::Application.load_tasks

def run_against_database(name: :mysql)
  adapter_name = name == :mysql ? "mysql2" : "postgresql"
  config_name, _adapter = check_for_test_configuration(adapter: adapter_name)

  if config_name.nil?
    puts "No configuration found for adapter #{adapter_name}, please check config/database.yml"
    return
  end

  puts "Running specs against #{name}"
  rename_test_configuration(config_name) do
    Rake::Task['spec'].reenable
    Rake::Task['spec'].invoke
  end
end

def check_for_test_configuration(adapter: "mysql2")
  configurations = Rails.application.config.database_configuration
  names_with_adapters = configurations.map {|key, value| [key, value.dig("adapter")] }
  matching = names_with_adapters.select do |pair|
    pair.first.match?(/test/) && pair.last.eql?(adapter)
  end
  matching.flatten
end

def rename_test_configuration(name)
  trap("INT") do
    puts "Shutting down..."
    system("sed -i -e 's/test:/#{name}:/' config/database.yml")
  end

  print "Renaming #{name} into test"
  system("sed -i -e 's/#{name}:/test:/' config/database.yml")
  yield if block_given?
  print "Renaming test into #{name}"
  system("sed -i -e 's/test:/#{name}:/' config/database.yml")
end

## We can't really enable this cop since there should be no 'test' environment
## in the sample configuration
# rubocop:disable Rails/RakeEnvironment
task :custom_spec do
  run_against_database(name: :mysql)
  run_against_database(name: :postgresql)
end
# rubocop:enable Rails/RakeEnvironment

# Clear off the default RSpec task
Rake::Task[:default].clear
task :default => :custom_spec
