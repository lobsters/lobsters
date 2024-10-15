# typed: false

require "rails_helper"

describe "origin routing" do
  it "routes a single origin" do
    assert_recognizes({controller: "home", action: "for_origin", identifier: "github.com/alice"}, "/origins/github.com/alice")
  end

  it "redirects attempts to load an identifier from a domain url", type: :request do
    get "/domains/github.com/alice"
    expect(response).to redirect_to("/origins/github.com/alice")
  end
end
