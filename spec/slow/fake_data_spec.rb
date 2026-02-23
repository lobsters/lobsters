# typed: false

require "rails_helper"

Rails.application.load_tasks

describe "fake_data" do
  # Delete the system user created by the rails helper since the seeds contain the same user.
  before { User.find_by(username: "System").destroy && Rails.application.load_seed }

  # basic smoke test, task shouldn't throw exceptions
  it "runs" do
    FakeDataGenerator.new.generate
  end
end
