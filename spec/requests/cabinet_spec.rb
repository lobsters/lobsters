require "rails_helper"

RSpec.describe "Cabinets", type: :request do
  it "loads" do
    get "/cabinet"
    expect(response.status).to eq(200)
  end
end
