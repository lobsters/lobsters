source "https://rubygems.org"

gem "rails"

gem "mysql2"
gem "sidekiq"

# rails
gem "scenic"
gem "scenic-mysql_adapter"
gem "activerecord-typedstore"
gem "sprockets-rails", require: "sprockets/railtie"

# js
gem "json"
gem "uglifier"

# deployment
gem "actionpack-page_caching"
gem "exception_notification"
gem "puma"

# security
gem "bcrypt"
gem "rotp"
gem "rqrcode"

# parsing
gem "commonmarker"
gem "htmlentities"
gem "pdf-reader"
gem "nokogiri"
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
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "standard"
  gem "standard-performance"
  gem "standard-rails"
  gem "standard-sorbet"
  gem "faker"
  gem "byebug"
  gem "rb-readline"
  gem "vcr"
  gem "webmock" # used to support vcr
  gem "simplecov", require: false
end
