# typed: false

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "simplecov"
require "super_diff/rspec-rails"

SimpleCov.start "rails"
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob("spec/support/**/*.rb").sort.each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation

    c = Category.create! category: "category1"
    # 'placeholder' is so factory_bot can instantiate valid Story objects, but tests must replace
    # that with their own tags if they care what a story is tagged
    c.tags.create!([{tag: "placeholder"}, {tag: "tag1"}, {tag: "tag2"}])
  end

  config.before(:example) do
    DatabaseCleaner.start
  end

  config.after(:example) do
    DatabaseCleaner.clean
    # Admitted a little hacky. prod memoizes to save db hits but tests recreate.
    InactiveUser.instance_variable_set(:@inactive_user, nil)
  end

  config.before(:example, :js) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:example, :truncate) do
    DatabaseCleaner.strategy = :truncation
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.infer_spec_type_from_file_location!
  config.raise_errors_for_deprecations!

  config.include AuthenticationHelper::FeatureHelper, type: :feature
  config.include AuthenticationHelper::RequestHelper, type: :request

  config.filter_rails_from_backtrace!
  config.filter_gems_from_backtrace \
    "bullet",
    "capybara",
    "rack",
    "rack-test",
    "railties",
    "scout_apm_ruby"
end

RSpec::Expectations.configuration.on_potential_false_positives = :nothing

# Checks for pending migration and applies them before tests are run.
ActiveRecord::Migration.maintain_test_schema!

def sent_emails
  ActionMailer::Base.deliveries
end

SuperDiff.configure do |config|
  config.diff_elision_enabled = false
  config.diff_elision_maximum = 3
  config.key_enabled = false
end
