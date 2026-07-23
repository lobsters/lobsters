# typed: false

require "rails_helper"

RSpec.describe "IP spoofing protection", type: :request do
  it "doesn't raise on normal traffic" do
    get "/", headers: {"HTTP_CLIENT_IP" => "1.2.3.4", "HTTP_X_FORWARDED_FOR" => "1.2.3.4"}
    expect(response.status).to eq(200)
  end

  it "renders 400 on mismatched headers" do
    get "/", headers: {"HTTP_CLIENT_IP" => "1.2.3.4", "HTTP_X_FORWARDED_FOR" => "6.7.8.9"}
    expect(response.status).to eq(400)
    expect(response.body).to include("implausible VPN")
  end
end
