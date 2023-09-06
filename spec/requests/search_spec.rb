require "rails_helper"

RSpec.describe "search controller", type: :request do
  it "loads the search form" do
    get "/search"
    expect(response).to be_successful
  end

  it "can find zero hits" do
    get "/search", params: {q: "aaa"}

    expect(response).to be_successful
    expect(response.body).to include("0 results")
  end
end
