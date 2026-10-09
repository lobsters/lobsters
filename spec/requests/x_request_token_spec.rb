# typed: false

require "rails_helper"

describe "XRequestToken", type: :request do
  it "generates a token" do
    get "/"
    expect(response.headers["X-Request-Token"]).to match(/\Arequest_[0-9a-z]{26}\z/)
    expect(response.headers["X-Request-Id"]).to be_nil
  end
end
