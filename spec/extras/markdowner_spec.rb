# typed: false

require "rails_helper"

describe Markdowner do
  it "parses simple markdown" do
    expect(Markdowner.to_html("hello there *italics* and **bold**!"))
      .to eq("<p>hello there <em>italics</em> and <strong>bold</strong>!</p>\n")
  end

  it "turns @username into a link if @username exists" do
    create(:user, username: "blahblah")

    expect(Markdowner.to_html("hi @blahblah test"))
      .to eq("<p>hi <a href=\"https://#{Rails.application.domain}/~blahblah\" rel=\"ugc\">" \
             "@blahblah</a> test</p>\n")

    expect(Markdowner.to_html("hi @flimflam test"))
      .to eq("<p>hi @flimflam test</p>\n")
  end

  it "turns ~username into a link if ~username exists" do
    create(:user, username: "blahblah")

    expect(Markdowner.to_html("hi ~blahblah test"))
      .to eq("<p>hi <a href=\"https://#{Rails.application.domain}/~blahblah\" rel=\"ugc\">" \
             "~blahblah</a> test</p>\n")

    expect(Markdowner.to_html("hi ~flimflam test")).to eq("<p>hi ~flimflam test</p>\n")
  end

  it "hyperlinks usernames based on when they existed, not now" do
    user = create :user, username: "alice", created_at: 4.weeks.ago
    Username.rename! user:, from: "alice", to: "bob", by: user, at: 1.week.ago

    str = "I like ~alice's code"
    # user didn't exist yet, so if a comment mentioned, no link
    expect(Markdowner.to_html(str, as_of: 6.weeks.ago)).not_to include("href=")
    # user existed when comment was written, so create a link
    expect(Markdowner.to_html(str, as_of: 2.weeks.ago)).to include("href=")
    # user renamed away, so if a comment mentioned now, no link
    expect(Markdowner.to_html(str, as_of: Time.current)).not_to include("href=")
  end

  # bug#209
  it "keeps punctuation inside of auto-generated links when using brackets" do
    expect(Markdowner.to_html("hi <http://example.com/a.> test"))
      .to eq("<p>hi <a href=\"http://example.com/a.\" rel=\"ugc\">" \
            "http://example.com/a.</a> test</p>\n")
  end

  # bug#242
  it "does not expand @ signs inside urls" do
    create(:user, username: "blahblah")

    expect(Markdowner.to_html("hi http://example.com/@blahblah/ test"))
      .to eq("<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"ugc\">" \
            "http://example.com/@blahblah/</a> test</p>\n")

    expect(Markdowner.to_html("hi [test](http://example.com/@blahblah/)"))
      .to eq("<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"ugc\">" \
        "test</a></p>\n")
  end

  it "adds ugc" do
    expect(Markdowner.to_html("[full URL](http://example.com)"))
      .to eq("<p><a href=\"http://example.com\" rel=\"ugc\">full URL</a></p>\n")

    expect(Markdowner.to_html("[protocol-relative URL](//example.com)"))
      .to eq("<p><a href=\"//example.com\" rel=\"ugc\">protocol-relative URL</a></p>\n")

    # invalid URLs that are still parsed as links (not an exhaustive list)
    expect(Markdowner.to_html("[missing protocol](example.com)"))
      .to eq("<p><a href=\"example.com\" rel=\"ugc\">missing protocol</a></p>\n")

    expect(Markdowner.to_html("[wrong number of slashes after protocol](http:/example.com)"))
      .to eq("<p><a href=\"http:/example.com\" rel=\"ugc\">wrong number of slashes after protocol</a></p>\n")

    # relative links
    expect(Markdowner.to_html("[relative link](/example)"))
      .to eq("<p><a href=\"/example\" rel=\"ugc\">relative link</a></p>\n")

    expect(Markdowner.to_html("[relative link to user profile](/~abc)"))
      .to eq("<p><a href=\"/~abc\" rel=\"ugc\">relative link to user profile</a></p>\n")

    # autolink
    expect(Markdowner.to_html("www.example.com"))
      .to eq("<p><a href=\"http://www.example.com\" rel=\"ugc\">www.example.com</a></p>\n")
  end

  it "escapes raw HTML" do
    # Examples adapted from https://cheatsheetseries.owasp.org/cheatsheets/XSS_Filter_Evasion_Cheat_Sheet.html

    expect(Markdowner.to_html("hi <script src=\"https://lobste.rs\"></script> bye"))
      .to eq("<p>hi &lt;script src=\"https://lobste.rs\"&gt;&lt;/script&gt; bye</p>\n")

    expect(Markdowner.to_html("hi <a onmouseover=\"alert('xss')\">xss</a> bye"))
      .to eq("<p>hi &lt;a onmouseover=\"alert('xss')\"&gt;xss&lt;/a&gt; bye</p>\n")

    expect(Markdowner.to_html("hi <img \"\"\"><script>alert('xss')</script> bye\">"))
      .to eq("<p>hi &lt;img \"\"\"&gt;&lt;script&gt;alert('xss')&lt;/script&gt; bye\"&gt;</p>\n")

    expect(Markdowner.to_html("hi <iframe src=\"javascript:alert('xss');\"></iframe> bye"))
      .to eq("<p>hi &lt;iframe src=\"javascript:alert('xss');\"&gt;&lt;/iframe&gt; bye</p>\n")
  end

  # issue #1727
  it "doesn't autolink bare triggers" do
    expect(Markdowner.to_html("hi www. bye"))
      .to eq("<p>hi www. bye</p>\n")

    expect(Markdowner.to_html("hi http:// bye"))
      .to eq("<p>hi http:// bye</p>\n")
  end

  context "when images are not allowed" do
    subject { Markdowner.to_html(description, allow_images: false) }

    let(:fake_img_url) { "https://lbst.rs/fake.jpg" }

    context "when single inline image in description" do
      let(:description) { "![#{alt_text}](#{fake_img_url} \"#{title_text}\")" }
      let(:alt_text) { nil }
      let(:title_text) { nil }

      def target_html inner_text = nil
        "<p><a href=\"#{fake_img_url}\" rel=\"ugc\">#{inner_text}</a></p>\n"
      end

      context "with no alt text, title text" do
        it "turns inline image into links with the url as the default text" do
          expect(subject).to eq(target_html(fake_img_url))
        end
      end

      context "with title text" do
        let(:title_text) { "title text" }

        it "turns inline image into links with title text" do
          expect(subject).to eq(target_html(title_text))
        end
      end

      context "with alt text" do
        let(:alt_text) { "alt text" }

        it "turns inline image into links with alt text" do
          expect(subject).to eq(target_html(alt_text))
        end
      end

      context "with title text and alt text" do
        let(:title_text) { "title text" }

        it "turns inline image into links, preferring title text" do
          expect(subject).to eq(target_html(title_text))
        end
      end
    end

    context "with multiple inline images in description" do
      let(:description) do
        "![](#{fake_img_url})" \
        "![](#{fake_img_url})" \
        "![alt text](#{fake_img_url})" \
        "![](#{fake_img_url} \"title text\")" \
        "![alt text](#{fake_img_url} \"title text 2\")"
      end

      it "turns all inline images into links" do
        expect(subject).to eq(
          "<p>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">#{fake_img_url}</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">#{fake_img_url}</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">alt text</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">title text</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">title text 2</a>" \
          "</p>\n"
        )
      end
    end
  end

  context "when images are allowed" do
    subject { Markdowner.to_html("![](https://lbst.rs/fake.jpg)", allow_images: true) }

    it "allows image tags" do
      expect(subject).to include "<img"
    end
  end
end
