require "spec_helper"

describe Markdowner do
  it "parses simple markdown" do
    Markdowner.to_html("hello there *italics* and **bold**!").should ==
      "<p>hello there <em>italics</em> and <strong>bold</strong>!</p>"
  end

  it "turns @username into a link if @username exists" do
    User.make!(:username => "blahblah")

    Markdowner.to_html("hi @blahblah test").should ==
      "<p>hi <a href=\"/u/blahblah\">@blahblah</a> test</p>"

    Markdowner.to_html("hi @flimflam test").should ==
      "<p>hi @flimflam test</p>"
  end

  # bug#209
  it "keeps punctuation inside of auto-generated links when using brackets" do
    Markdowner.to_html("hi <http://example.com/a.> test").should ==
      "<p>hi <a href=\"http://example.com/a.\" rel=\"nofollow\">" <<
        "http://example.com/a.</a> test</p>"
  end

  # bug#242
  it "does not expand @ signs inside urls" do
    User.make!(:username => "blahblah")

    Markdowner.to_html("hi http://example.com/@blahblah/ test").should ==
      "<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"nofollow\">" <<
        "http://example.com/@blahblah/</a> test</p>"

    Markdowner.to_html("hi [test](http://example.com/@blahblah/)").should ==
      "<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"nofollow\">" <<
        "test</a></p>"
  end

  it "correctly adds nofollow" do
    Markdowner.to_html("[ex](http://example.com)").should ==
      "<p><a href=\"http://example.com\" rel=\"nofollow\">" <<
        "ex</a></p>"

    Markdowner.to_html("[ex](//example.com)").should ==
      "<p><a href=\"//example.com\" rel=\"nofollow\">" <<
        "ex</a></p>"

    Markdowner.to_html("[ex](/u/abc)").should ==
      "<p><a href=\"/u/abc\">ex</a></p>"
  end
end
