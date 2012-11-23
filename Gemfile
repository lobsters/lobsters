source "https://rubygems.org"

# Frameworks
gem "rails", "~> 3.2"

# Servers
gem "unicorn", "~> "

# Helpers
gem "dynamic_form", "~> "

# HTML Parsing
gem "nokogiri", "~> "
gem "htmlentities", "~> "

# Rendering Engines
gem "rdiscount", "~> "

# Search Engines
gem "thinking-sphinx", "2.0.12"

group :production do
  gem "mysql2", "~> "
  gem "exception_notification", "~> "
end

group :test, :development do
  gem "rspec-rails", "~> 2.6"
  gem "machinist", "~> "
  gem "sqlite3", "~> "
end

group :development do

end

group :test do

end

group :assets do
  gem "uglifier"
  gem "jquery-rails"
end
