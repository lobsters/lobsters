# typed: false

require "rails_helper"

RSpec.describe RefillStoryPageCacheJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let!(:story1) { create(:story) }
    let!(:story2) { create(:story) }

    it "queues jobs to rerender all stories" do
      assert_enqueued_jobs(0)
      RefillStoryPageCacheJob.perform_now
      assert_enqueued_jobs(2, queue: :idle)
    end
  end
end
