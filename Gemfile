source "https://rubygems.org"

gem "json"
gem "rails", "~> 5.1"

gem "unicorn"

gem "mysql2", "~> 0.3.20"

# uncomment to use PostgreSQL
# gem "pg"

gem 'scenic'
gem 'scenic-mysql'

gem "uglifier", ">= 1.3.0"
gem "jquery-rails", "~> 4.3"
gem "dynamic_form"

gem "bcrypt", "~> 3.1.2"
gem "rotp"
gem "rqrcode"

gem "nokogiri", ">= 1.7.2"
gem "htmlentities"
gem "commonmarker", "~> 0.14"

gem "activerecord-typedstore"

# for twitter-posting bot
gem "oauth"

# for parsing incoming mail
gem "mail"

group :production do
  gem "exception_notification"
  gem "skylight"
end

group :test, :development do
  gem 'bullet'
  gem "rspec-rails"
  gem "machinist"
  gem "rubocop", require: false
  gem "sqlite3"
  gem "faker"
end
