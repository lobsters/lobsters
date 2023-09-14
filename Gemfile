source "https://rubygems.org"

gem "rails"

gem "mysql2"

# uncomment to use PostgreSQL
# gem "pg"

# rails
gem "scenic"
gem "scenic-mysql_adapter"
gem "activerecord-typedstore"
gem "sprockets-rails", "2.3.3"

# js
gem "jquery-rails", "~> 4.3"
gem "json"
gem "uglifier", ">= 1.3.0"

# deployment
gem "actionpack-page_caching"
gem "exception_notification"
gem "puma", ">= 5.6.2"

# security
gem "bcrypt", "~> 3.1.2"
gem "rotp"
gem "rqrcode"

# parsing
gem "commonmarker", ">= 0.23.6"
gem "htmlentities"
gem "pdf-reader"
gem "nokogiri", ">= 1.13.9"
gem "parslet"

# perf
gem "flamegraph"
gem "memory_profiler"
gem "rack-mini-profiler"
gem "stackprof"

gem "oauth" # for twitter-posting bot
gem "mail" # for parsing incoming mail
gem "sitemap_generator" # for better search engine indexing
gem "svg-graph", require: "SVG/Graph/TimeSeries" # for charting, note workaround in lib/time_series.rb
gem "rack-attack" # rate-limiting

group :test, :development do
  gem "benchmark-perf"
  gem "capybara"
  gem "database_cleaner"
  gem "listen"
  gem "rspec-rails", "~> 6.0.0.rc1"
  gem "factory_bot_rails"
  gem "standard"
  gem "standard-rails"
  gem "standard-sorbet"
  gem "faker"
  gem "byebug"
  gem "rb-readline"
  gem "vcr"
  gem "webmock" # used to support vcr
  gem "simplecov", require: false
end
