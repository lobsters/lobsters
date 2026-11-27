require "rails_helper"

describe "avatars", type: :request do
  describe "show" do
    let(:user) { create(:user) }
    let(:cached) { Rails.public_path.join("avatars", "#{user.username}-100.png") }

    after { FileUtils.rm_f(cached) }

    it "serves the fetched avatar and caches it in public/" do
      image = "\x89PNG not really".b
      allow_any_instance_of(User).to receive(:fetched_avatar).and_return(image)

      get "/avatars/#{user.username}-100.png"

      expect(response).to be_successful
      expect(response.media_type).to eq("image/png")
      expect(response.body.b).to eq(image)
      expect(File.binread(cached)).to eq(image)
    end
  end
end
