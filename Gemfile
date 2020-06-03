source "https://rubygems.org"

gem "rails", "~> 5.2.4.3"

gem "mysql2"

# uncomment to use PostgreSQL
# gem "pg"

# rails
gem 'scenic'
gem 'scenic-mysql_adapter'
gem "activerecord-typedstore"
gem 'sprockets-rails', '2.3.3'

# js
gem "dynamic_form"
gem "jquery-rails", "~> 4.3"
gem "json"
gem "uglifier", ">= 1.3.0"

# deployment
gem "actionpack-page_caching"
gem "exception_notification"
gem "puma"

# security
gem "bcrypt", "~> 3.1.2"
gem "rotp"
gem "rqrcode"

# parsing
gem "pdf-reader"
gem "nokogiri", ">= 1.10.8"
gem "htmlentities"
gem "commonmarker", "~> 0.14"

gem "oauth" # for twitter-posting bot
gem "mail" # for parsing incoming mail
gem "ruumba" # tests views
gem "sitemap_generator" # for better search engine indexing
gem 'transaction_retry' # mitigate https://github.com/lobsters/lobsters-ansible/issues/39

group :test, :development do
  gem 'bullet'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'good_migrations'
  gem "listen"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "rubocop", "0.81", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "faker"
  gem "byebug"
  gem "rb-readline"
end
