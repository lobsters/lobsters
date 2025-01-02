# typed: false

require "rails_helper"

describe "stories", type: :request do
  describe "all" do
    let!(:story1) { create(:story, url: "https://example.com/1", created_at: 90.days.ago) }
    let!(:story2) { create(:story, url: "https://example.com/1", created_at: 1.day.ago) }

    it "returns all subsmissions of the given url" do
      get "/stories/url/all.json", params: {url: "https://example.com/1"}
      expect(response.status).to eq(200)
      stories = JSON.parse(response.body)
      expect(stories.size).to eq(2)
      expect(stories.first["short_id"]).to eq(story2.short_id)
    end

    it "doesn't error if not given a url" do
      get "/stories/url/all.json", params: {}
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({"error" => "param is missing or the value is empty or invalid: url"})
    end

    it "doesn't error if the url hasn't been submitted" do
      get "/stories/url/all", params: {url: "https://notsubmitted.net"}
      expect(response.status).to eq(404)
    end
  end

  describe "latest" do
    let!(:story1) { create(:story, url: "https://example.com/1", created_at: 90.days.ago) }
    let!(:story2) { create(:story, url: "https://example.com/1", created_at: 1.day.ago) }

    it "redirects to latest subsmission of the given url" do
      get "/stories/url/latest", params: {url: "https://example.com/1"}
      expect(response.status).to eq(302)
      expect(response).to redirect_to(story2.comments_path)
    end

    describe "a url that hasn't been submitted" do
      it "redirects users to submit" do
        sign_in create(:user)

        get "/stories/url/latest", params: {url: "https://nogweii.net/"}
        expect(response.status).to eq(302)
        expect(response).to redirect_to("/stories/new")
      end

      it "404s for visitors" do
        expect {
          get "/stories/url/latest", params: {url: "https://nogweii.net"}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
