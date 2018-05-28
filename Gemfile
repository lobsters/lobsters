source "https://rubygems.org"

gem "rails", "~> 5.2.0"

gem "mysql2", "~> 0.4.10"

# uncomment to use PostgreSQL
# gem "pg"

# rails
gem 'scenic'
gem 'scenic-mysql'
gem "activerecord-typedstore"

# js
gem "dynamic_form"
gem "jquery-rails", "~> 4.3"
gem "json"
gem "uglifier", ">= 1.3.0"

# deployment
gem "actionpack-page_caching"
gem "exception_notification"
gem "unicorn"

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# security
gem "bcrypt", "~> 3.1.2"
gem "rotp"
gem "rqrcode"

# parsing
gem "nokogiri", ">= 1.7.2"
gem "htmlentities"
gem "commonmarker", "~> 0.14"

# for twitter-posting bot
gem "oauth"

# for parsing incoming mail
gem "mail"

group :test, :development do
  gem 'bullet'
  gem 'capybara'
  gem "rspec-rails"
  gem "machinist"
  gem "rubocop", require: false
  gem "sqlite3"
  gem "faker"
  gem "byebug"
  gem 'listen'
end
