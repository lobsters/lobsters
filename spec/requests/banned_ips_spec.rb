require "rails_helper"

RSpec.describe "BannedIps", type: :request do
  describe "GET /banned-ips" do
    it "loads" do
      get "/banned-ips"
      expect(response.status).to eq(200)
    end
  end
end
