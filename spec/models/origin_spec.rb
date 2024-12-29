# typed: false

require "rails_helper"

RSpec.describe Origin, type: :model do
  self.use_transactional_tests = false

  before(:all) do
    DatabaseCleaner.strategy = :truncation
  end

  describe "two (or more?) concurrent attempts to find or create the origin for an url" do
    it "at most one succeeds to create the record while the others retrieve it from the database" do
      domain = Domain.create! domain: "github.com",
        selector: "\\Ahttps://(github.com/[^/]+).*\\z",
        replacement: "\\1"

      # Thread.abort_on_exception = true
      record_not_unique_error_raised = false
      threads = []
      2.times do
        threads << Thread.new do
          domain.find_or_create_origin("https://github.com/foo")
        rescue ActiveRecord::RecordNotUnique
          record_not_unique_error_raised = true
        end
      end
      threads.each(&:join)

      expect(record_not_unique_error_raised).to be false
    end
  end
end
