source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails"

# database and caching
gem "solid_cache"
gem "sqlite3"
gem "trilogy"

# jobs
gem "solid_queue"
gem "mission_control-jobs"

# rails
gem "activerecord-typedstore"
gem "importmap-rails", "~> 2.0"
gem "propshaft"
gem "sentry-rails"
gem "typeid"

# js
gem "json"

# deployment
gem "actionpack-page_caching"
gem "puma"

# security
gem "bcrypt"
gem "rotp"
gem "rqrcode"

# parsing
gem "cgi"
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

gem "builder" # for rss
gem "faker" # for factory data and /cabinet
gem "oauth" # for linking accounts
gem "mail" # for parsing incoming mail
gem "sitemap_generator" # for better search engine indexing
gem "svg-graph", require: "SVG/Graph/TimeSeries" # for charting, note workaround in lib/time_series.rb
gem "rexml" # no release for https://github.com/lumean/svg-graph2/pull/48/files
gem "rack-attack" # rate-limiting
gem "lograge" # for JSON logging
gem "silencer" # to disable default logging in prod

# image
gem "ruby-vips"

group :test, :development do
  gem "active_record_doctor"
  gem "benchmark-perf"
  gem "brakeman"
  gem "pry-byebug"
  gem "pry-rails"
  gem "capybara"
  gem "database_cleaner"
  gem "database_consistency"
  gem "factory_bot_rails"
  gem "foreman"
  gem "letter_opener"
  gem "listen"
  gem "ostruct" # for foreman on Ruby 4, probably safe to delete after 2026-06
  gem "rb-readline"
  gem "rspec-rails"
  gem "simplecov", require: false
  gem "standard"
  gem "standard-performance"
  gem "standard-rails"
  gem "super_diff"
  gem "vcr"
  gem "webmock" # used to support vcr
end
