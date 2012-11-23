source "https://rubygems.org"

# Frameworks
gem "rails", "~> 3.2"

# Servers
gem "unicorn", "~> 4.3"

# Helpers
gem "dynamic_form", "~> 1.1"

# HTML Parsing
gem "nokogiri", "~> 1.5"
gem "htmlentities", "~> 4.3"

# Rendering Engines
gem "rdiscount", "~> 1.6"

# Search Engines
gem "thinking-sphinx", "~> 2.0"

group :production do
  gem "mysql2", "~> 0.3"
  gem "exception_notification", "~> 3.0"
end

group :test, :development do
  gem "rspec-rails", "~> 2.6"
  gem "machinist", "~> 2.0"
  gem "sqlite3", "~> 1.3"
end

group :development do

end

group :test do

end

group :assets do
  gem "uglifier", "~> 1.2"
  gem "jquery-rails", "~> 2.0"
end
