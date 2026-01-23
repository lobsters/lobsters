require "rails_helper"

RSpec.describe StoryImage, type: :model do
  describe "#generate" do
    let(:story) { create(:story, url: "http://example.com/story") }
    let(:story_image) { StoryImage.new(story) }

    it "handles download failures" do
      allow(story_image).to receive(:fetch_url).with(story.url).and_return(nil)

      expect {
        story_image.generate(story.url)
      }.not_to change { story_image.exists? }
    end

    it "skips large images" do
      html_response = double("Net::HTTPSuccess", body: '<html><meta property="og:image" content="http://example.com/huge.png"></html>')
      allow(html_response).to receive(:[]).with("content-type").and_return("text/html")
      allow(story_image).to receive(:fetch_url).with(story.url).and_return(html_response)

      large_body = "0" * (8.megabytes + 1)
      image_response = double("Net::HTTPSuccess", body: large_body)
      allow(story_image).to receive(:fetch_url).with("http://example.com/huge.png").and_return(image_response)

      expect {
        story_image.generate(story.url)
      }.not_to change { story_image.exists? }
    end
  end
end
