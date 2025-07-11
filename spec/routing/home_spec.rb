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

  describe "top" do
    it "routes /top" do
      expect(get("/top")).to route_to("home#top")
    end

    it "routes /top/rss" do
      expect(get("/top/rss")).to route_to("home#top", format: "rss")
    end

    it "routes /top/1w" do
      expect(get("/top/1w")).to route_to("home#top", length: "1w")
    end

    it "routes /top/1w/rss" do
      expect(get("/top/1w/rss")).to route_to("home#top", length: "1w", format: "rss")
    end

    it "routes /top/1w/page/2" do
      expect(get("/top/1w/page/2")).to route_to("home#top", length: "1w", page: "2")
    end

    it "generates the correct path for paginated top stories" do
      expect(url_for(controller: "home", action: "top", length: "1w", page: 2, only_path: true)).to eq("/top/1w/page/2")
    end
  end
end
