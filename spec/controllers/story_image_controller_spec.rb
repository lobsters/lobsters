require "rails_helper"

RSpec.describe StoryImageController, type: :controller do
  describe "GET show" do
    let(:story) { create(:story) }
    let(:cache_dir) { Rails.public_path.join("story_image/") }
    let(:cached_image) { cache_dir.join("#{story.short_id}.png") }

    before do
      FileUtils.mkdir_p(cache_dir)
    end

    after do
      FileUtils.rm_f(cached_image)
    end

    context "when the image exists" do
      before do
        FileUtils.touch(cached_image)
      end

      it "returns the image inline" do
        get :show, params: {short_id: story.short_id, format: :png}
        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Type"]).to eq("image/png")
        expect(response.headers["Content-Disposition"]).to include("inline")
      end
    end

    context "when the image does not exist" do
      let(:logo_path) { Rails.public_path.join("touch-icon-144.png") }

      it "does not enqueue CreateStoryCardJob" do
        expect {
          get :show, params: {short_id: story.short_id, format: :png}
        }.not_to have_enqueued_job(CreateStoryCardJob)
      end

      it "serves the fallback logo" do
        get :show, params: {short_id: story.short_id, format: :png}
        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Type"]).to eq("image/png")
        expect(response.body.bytesize).to eq(File.size(logo_path))
      end
    end
  end
end
