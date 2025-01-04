require 'rails_helper'

RSpec.describe "Suggestions", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/suggestions/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/suggestions/new"
      expect(response).to have_http_status(:success)
    end
  end

end
