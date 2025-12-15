# typed: false

require "rails_helper"

describe "tag routing" do
  it "routes a single tag" do
    assert_recognizes({controller: "home", action: "single_tag", tag: "foo"}, "/t/foo")
  end

  it "routes a single tag, page 2" do
    assert_recognizes({controller: "home", action: "single_tag", tag: "foo", page: "2"}, "/t/foo/page/2")
  end

  it "routes a single tag rss feed" do
    assert_recognizes(
      {controller: "home", action: "single_tag", tag: "foo", format: "rss"},
      "/t/foo.rss"
    )
  end

  it "routes multiple tags" do
    assert_recognizes(
      {controller: "home", action: "multi_tag", tag: "foo,bar"},
      "/t/foo,bar"
    )
  end

  it "routes multiple tags, page 2" do
    assert_recognizes(
      {controller: "home", action: "multi_tag", tag: "foo,bar", page: "2"},
      "/t/foo,bar/page/2"
    )
  end

  it "routes multiple tags rss feed" do
    assert_recognizes(
      {controller: "home", action: "multi_tag", tag: "foo,bar", format: "rss"},
      "/t/foo,bar.rss"
    )
  end

  # ONE tag has gotta be clever
  it "routes the c++ tag" do
    assert_recognizes({controller: "home", action: "single_tag", tag: "c++"}, "/t/c++")
    assert_recognizes(
      {controller: "home", action: "single_tag", tag: "c++", format: "rss"},
      "/t/c++.rss"
    )
  end
end
