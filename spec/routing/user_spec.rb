# typed: false

require "rails_helper"

describe "user routing" do
  it "users#tree" do
    assert_routing(
      "/users",
      controller: "users", action: "tree"
    )
  end

  it "users#show" do
    assert_routing(
      "/~alice",
      controller: "users", action: "show", username: "alice"
    )
  end

  it "home#stories" do
    assert_routing(
      "/~alice/stories",
      controller: "home", action: "newest_by_user", user: "alice"
    )
    assert_routing(
      "/~alice/stories/page/2",
      controller: "home", action: "newest_by_user", user: "alice", page: "2"
    )
  end

  it "comments#user_threads" do
    assert_routing(
      "/~alice/threads",
      controller: "comments", action: "user_threads", user: "alice"
    )
  end
end

# odd Rails limitation: you can redirect from routes but not test those from routing tests
describe "user redirects", type: :request do
  it "old-style to tilde" do
    expect(get("/u/alice")).to redirect_to("/~alice")
  end

  it "user tree" do
    expect(get("/u")).to redirect_to("/users")
  end

  it "newest stories" do
    expect(get("/newest/alice")).to redirect_to("/~alice/stories")
    expect(get("/newest/alice/page/2")).to redirect_to("/~alice/stories/page/2")
  end

  it "threads" do
    expect(get("/threads/alice")).to redirect_to("/~alice/threads")
  end
end
