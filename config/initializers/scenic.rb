# frozen_string_literal: true

Scenic.configure do |config|
  config.database = Scenic::Adapters::MySQL.new
end
