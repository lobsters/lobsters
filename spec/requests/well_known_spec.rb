# typed: false

require "rails_helper"

describe "well-known", type: :request do
  describe "apple-app-site-association" do
    it "serves Pinchy's shared web credentials association" do
      get "/.well-known/apple-app-site-association"

      expect(response).to be_successful
      expect(response.media_type).to eq("application/json")
      expect(JSON.parse(response.body)).to eq(
        "webcredentials" => {
          "apps" => [
            "6YP6RAX9V5.com.scamallsoftware.Pinchy"
          ]
        }
      )
    end
  end
end
