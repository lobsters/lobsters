# typed: false

require "rails_helper"

describe "home routing" do
  it "routes a domain" do
    assert_recognizes(
      {controller: "home", action: "for_domain", id: "example.com", format: nil},
      "/domains/example.com"
    )
  end

  it "routes a domain rss feed" do
    assert_recognizes(
      {controller: "home", action: "for_domain", id: "example.com", format: "rss"},
      "/domains/example.com.rss"
    )
  end

  it "doesn't exhibit the rails misdesign from #746 and #1114" do
    # routes supported formats
    expect(get("/recent")).to route_to("home#recent", format: "html")
    expect(get("/recent.html")).to route_to("home#recent", format: "html")
    expect(get("/newest.rss")).to route_to("home#newest", format: "rss")
    expect(get("/newest.json")).to route_to("home#newest", format: "json")

    # doesn't route unannounced formats
    expect(get("/recent.rss")).not_to be_routable
    expect(get("/top.json")).not_to be_routable

    # definitely doesn't route nonsense formats
    expect(get("/newest.asdf")).not_to be_routable
  end

  describe "top" do
    it "routes /top" do
      expect(get("/top")).to route_to("home#top", format: nil)
    end

    it "routes /top.rss" do
      expect(get("/top.rss")).to route_to("home#top", format: "rss")
    end

    it "routes /top/1w" do
      expect(get("/top/1w")).to route_to("home#top", length: "1w", format: nil)
    end

    it "routes /top/1w.rss" do
      expect(get("/top/1w.rss")).to route_to("home#top", length: "1w", format: "rss")
    end

    it "routes /top/1w/page/2" do
      expect(get("/top/1w/page/2")).to route_to("home#top", length: "1w", page: "2", format: nil)
    end

    it "generates the correct path for paginated top stories" do
      expect(url_for(controller: "home", action: "top", length: "1w", page: 2, only_path: true)).to eq("/top/1w/page/2")
    end
  end

  describe "rss redirects", type: :request do
    it "/top/rss to /top.rss" do
      expect(get("/top/rss")).to redirect_to("/top.rss")
    end

    it "redirects /top/:length/rss to /top/:length.rss" do
      expect(get("/top/1w/rss")).to redirect_to("/top/1w.rss")
    end

    it "/comments/rss to /comments.rss" do
      expect(get("/comments/rss")).to redirect_to("/comments.rss")
    end
  end
end
