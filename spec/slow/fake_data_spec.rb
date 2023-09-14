# typed: false

require "rails_helper"

Rails.application.load_tasks

describe "fake_data" do
  before { Rails.application.load_seed }

  # basic smoke test, task shouldn't throw exceptions
  it "runs" do
    FakeDataGenerator.new.generate
  end
end
