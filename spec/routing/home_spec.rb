# typed: false

require "rails_helper"

describe "home routing" do
  it "routes a domain" do
    assert_recognizes(
      {controller: "home", action: "for_domain", id: "example.com"},
      "/domains/example.com"
    )
  end

  it "routes a domain rss feed" do
    assert_recognizes(
      {controller: "home", action: "for_domain", id: "example.com", format: "rss"},
      "/domains/example.com.rss"
    )
  end
end
