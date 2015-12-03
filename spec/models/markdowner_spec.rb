require "spec_helper"

describe Markdowner do
  it "parses simple markdown" do
    Markdowner.to_html("hello there *italics* and **bold**!").should ==
      "<p>hello there <em>italics</em> and <strong>bold</strong>!</p>\n"
  end

  it "turns @username into a link if @username exists" do
    User.make!(:username => "blahblah")

    Markdowner.to_html("hi @blahblah test").should ==
      "<p>hi <a href=\"/u/blahblah\">@blahblah</a> test</p>\n"

    Markdowner.to_html("hi @flimflam test").should ==
      "<p>hi @flimflam test</p>\n"
  end

  it "moves punctuation outside of auto-generated links" do
    Markdowner.to_html("hi http://example.com/a! test").should ==
      "<p>hi <a rel=\"nofollow\" " <<
        "href=\"http://example.com/a\">http://example.com/a</a>! test</p>\n"
  end

  # bug#209
  it "keeps punctuation inside of auto-generated links when using brackets" do
    Markdowner.to_html("hi <http://example.com/a.> test").should ==
      "<p>hi <a rel=\"nofollow\" " <<
        "href=\"http://example.com/a.\">http://example.com/a.</a> test</p>\n"
  end

  # bug#242
  it "does not expand @ signs inside urls" do
    User.make!(:username => "blahblah")

    Markdowner.to_html("hi http://example.com/@blahblah/ test").should ==
      "<p>hi <a rel=\"nofollow\" " <<
        "href=\"http://example.com/@blahblah/\">http://example.com/@blahblah</a></p>\n"

    Markdowner.to_html("hi [test](http://example.com/@blahblah/)").should ==
      "<p>hi <a rel=\"nofollow\" " <<
        "href=\"http://example.com/@blahblah/\">test</a></p>\n"
  end
end
