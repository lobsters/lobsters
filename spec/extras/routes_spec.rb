# typed: false

require "rails_helper"

describe Routes do
  it "has access to rails routes" do
    expect(Routes.root_path).to eq "/"
  end

  it "routes to stories with titles as slugs" do
    s = Story.new(short_id: "abc123", title: "Hello world!")
    expect(Routes.title_path(s)).to eq "/s/abc123/hello_world"
  end

  it "routes title_path with anchor" do
    s = Story.new(short_id: "abc123", title: "Hello world!")
    expect(Routes.title_path(s, anchor: "footer")).to eq "/s/abc123/hello_world#footer"
  end

  it "routes to comments with anchors" do
    s = Story.new(short_id: "abc123", title: "Hello world!")
    c = Comment.new(story: s, short_id: "def456")
    expect(Routes.comment_target_path(c, true)).to eq "/s/abc123/hello_world#c_def456"
  end
end
