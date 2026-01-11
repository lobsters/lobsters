require "rails_helper"

RSpec.describe CreateStoryCardJob, type: :job do
  describe "#perform" do
    let(:story) { create(:story, url: "http://example.com/story") }
    let(:job) { CreateStoryCardJob.new }
    let(:story_image) { instance_double(StoryImage) }

    before do
      allow(StoryImage).to receive(:new).with(story).and_return(story_image)
    end

    it "calls generate on StoryImage" do
      expect(story_image).to receive(:generate).with(story.url)
      job.perform(story)
    end
  end
end
