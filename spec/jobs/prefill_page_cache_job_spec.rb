# typed: false

require "rails_helper"

RSpec.describe PrefillPageCacheJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let!(:story) { create(:story) }

    it "enqueues CachePageJobs for popular non-story pages" do
      PrefillPageCacheJob.perform_now

      ["/", "/active", "/recent", "/comments", "/newest", "/users", Routes.title_path(story)].each do |path|
        expect(CachePageJob).to have_been_enqueued.with(path)
      end
    end
  end
end
