# typed: false

require "rails_helper"

describe "Top page and RSS", type: :request do
  it "loads /top" do
    get "/top"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Top Stories")
  end

  it "loads /top.rss" do
    get "/top.rss"
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("application/rss+xml")
    expect(response.body).to include("<rss")
  end
end