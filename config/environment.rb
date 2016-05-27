# Load the Rails application.
require File.expand_path('../application', __FILE__)

DATABASE = YAML::load_file("#{Rails.root}/config/database.yml")[Rails.env]

# Initialize the Rails application.
Lobsters::Application.initialize!
