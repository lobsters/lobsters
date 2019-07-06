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

  context "when images are not allowed" do
    subject { Markdowner.to_html(description, allow_images: false) }

    let(:fake_img_url) { 'https://lbst.rs/fake.jpg' }

    context "when single inline image in description" do
      let(:description) { "![#{alt_text}](#{fake_img_url} \"#{title_text}\")" }
      let(:alt_text) { nil }
      let(:title_text) { nil }

      def target_html inner_text = nil
        "<p><a href=\"#{fake_img_url}\" rel=\"nofollow\">#{inner_text}</a></p>\n"
      end

      context "with no alt text, title text" do
        it "turns inline image into links with the url as the default text" do
          expect(subject).to eq(target_html(fake_img_url))
        end
      end

      context "with title text" do
        let(:title_text) { 'title text' }

        it "turns inline image into links with title text" do
          expect(subject).to eq(target_html(title_text))
        end
      end

      context "with alt text" do
        let(:alt_text) { 'alt text' }

        it "turns inline image into links with alt text" do
          expect(subject).to eq(target_html(alt_text))
        end
      end

      context "with title text" do
        let(:title_text) { 'title text' }

        it "turns inline image into links with title text" do
          expect(subject).to eq(target_html(title_text))
        end
      end

      context "with title text and alt text" do
        let(:title_text) { 'title text' }

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

      it 'turns all inline images into links' do
        expect(subject).to eq(
          "<p>" \
          "<a href=\"#{fake_img_url}\" rel=\"nofollow\">#{fake_img_url}</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"nofollow\">#{fake_img_url}</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"nofollow\">alt text</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"nofollow\">title text</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"nofollow\">title text 2</a>" \
          "</p>\n"
        )
      end
    end
  end

  context "when images are allowed" do
    subject { Markdowner.to_html("![](https://lbst.rs/fake.jpg)", allow_images: true) }

    it 'allows image tags' do
      expect(subject).to include '<img'
    end
  end
end
