require "rails_helper"

describe Markdowner do
  it "parses simple markdown" do
    expect(Markdowner.to_html("hello there *italics* and **bold**!"))
      .to eq("<p>hello there <em>italics</em> and <strong>bold</strong>!</p>\n")
  end

  it "turns @username into a link if @username exists" do
    create(:user, :username => "blahblah")

    expect(Markdowner.to_html("hi @blahblah test"))
      .to eq("<p>hi <a href=\"https://example.com/u/blahblah\" rel=\"nofollow\">" +
             "@blahblah</a> test</p>\n")

    expect(Markdowner.to_html("hi @flimflam test"))
      .to eq("<p>hi @flimflam test</p>\n")
  end

  # bug#209
  it "keeps punctuation inside of auto-generated links when using brackets" do
    expect(Markdowner.to_html("hi <http://example.com/a.> test"))
      .to eq("<p>hi <a href=\"http://example.com/a.\" rel=\"nofollow\">" +
            "http://example.com/a.</a> test</p>\n")
  end

  # bug#242
  it "does not expand @ signs inside urls" do
    create(:user, :username => "blahblah")

    expect(Markdowner.to_html("hi http://example.com/@blahblah/ test"))
      .to eq("<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"nofollow\">" +
            "http://example.com/@blahblah/</a> test</p>\n")

    expect(Markdowner.to_html("hi [test](http://example.com/@blahblah/)"))
      .to eq("<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"nofollow\">" +
        "test</a></p>\n")
  end

  it "correctly adds nofollow" do
    expect(Markdowner.to_html("[ex](http://example.com)"))
      .to eq("<p><a href=\"http://example.com\" rel=\"nofollow\">" +
            "ex</a></p>\n")

    expect(Markdowner.to_html("[ex](//example.com)"))
      .to eq("<p><a href=\"//example.com\" rel=\"nofollow\">" +
            "ex</a></p>\n")

    expect(Markdowner.to_html("[ex](/u/abc)"))
      .to eq("<p><a href=\"/u/abc\">ex</a></p>\n")
  end
end
