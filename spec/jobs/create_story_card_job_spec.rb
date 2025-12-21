require "rails_helper"

RSpec.describe CreateStoryCardJob, type: :job do
  describe "#perform" do
    let(:story) { create(:story, url: "http://example.com/story") }
    let(:job) { CreateStoryCardJob.new }

    before do
      allow(CreateStoryCardJob).to receive(:new).and_return(job)
    end

    it "handles download failures" do
      allow(job).to receive(:fetch_url).with(story.url).and_return(nil)

      expect {
        job.perform(story)
      }.not_to change { Rails.public_path.join("story_image/#{story.short_id}.png").exist? }
    end

    it "skips large images" do
      html_response = double("Net::HTTPSuccess", body: '<html><meta property="og:image" content="http://example.com/huge.png"></html>')
      allow(html_response).to receive(:[]).with("content-type").and_return("text/html")
      allow(job).to receive(:fetch_url).with(story.url).and_return(html_response)

      large_body = "0" * (8.megabytes + 1)
      image_response = double("Net::HTTPSuccess", body: large_body)
      allow(job).to receive(:fetch_url).with("http://example.com/huge.png").and_return(image_response)

      expect {
        job.perform(story)
      }.not_to change { Rails.public_path.join("story_image/#{story.short_id}.png").exist? }
    end
  end
end
