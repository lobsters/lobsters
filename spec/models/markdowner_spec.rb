require "rails_helper"

describe Markdowner do
  it "parses simple markdown" do
    expect(Markdowner.to_html("hello there *italics* and **bold**!"))
      .to eq("<p>hello there <em>italics</em> and <strong>bold</strong>!</p>\n")
  end

  # bug#1037
  context "when @username refers to an existing user" do
    it "turns into a link" do
      create(:user, :username => "blahblah")

      expect(Markdowner.to_html("hi @blahblah test"))
        .to eq("<p>hi <a href=\"#{Rails.application.root_url}u/blahblah\" rel=\"ugc\">" +
               "@blahblah</a> test</p>\n")
    end

    context "when @username contains repeated hyphens that would normally " \
            "be parsed into dashes" do
      it "turns into a link which includes the hyphens" do
        create(:user, :username => "blahblah--")
        create(:user, :username => "blah---blah")

        expect(Markdowner.to_html("hi @blahblah--"))
          .to eq("<p>hi <a href=\"#{Rails.application.root_url}u/blahblah--\" rel=\"ugc\">" +
                 "@blahblah--</a></p>\n")

        expect(Markdowner.to_html("hi @blah---blah test"))
          .to eq("<p>hi <a href=\"#{Rails.application.root_url}u/blah---blah\" rel=\"ugc\">" +
                 "@blah---blah</a> test</p>\n")
      end
    end

    context "when @username appears before a dash" do
      it "turns into a link without hyphens" do
        create(:user, :username => "blah")

        expect(Markdowner.to_html("hi @blah---blah test"))
          .to eq("<p>hi <a href=\"#{Rails.application.root_url}u/blah\" rel=\"ugc\">" +
                 "@blah</a>—blah test</p>\n")
      end
    end

    context "when @username contains pairs of underscores that would normally " \
            "be parsed into <em> tags" do
      it "turns into a link which includes the underscores" do
        create(:user, :username => "c-_-a_")

        expect(Markdowner.to_html("hi @c-_-a_ test _bye_"))
          .to eq("<p>hi <a href=\"#{Rails.application.root_url}u/c-_-a_\" rel=\"ugc\">" +
                 "@c-_-a_</a> test <em>bye</em></p>\n")
      end
    end
  end

  context "when @username does not refer to any existing user" do
    it "does not turn into a link" do
      expect(Markdowner.to_html("hi @flimflam-- test"))
        .to eq("<p>hi @flimflam– test</p>\n") # en dash
    end

    context "when the username is invalid and contains markdown formatting" do
      it "does not turn into a link and is formatted" do
        expect(Markdowner.to_html("hi @c-_-a_-too_long_for_a_user---name test _bye_"))
          .to eq("<p>hi @c-<em>-a</em>-too_long_for_a_user—name test <em>bye</em></p>\n")
      end
    end

    context "when the username is valid and contains markdown formatting" do
      it "does not turn into a link and is formatted" do
        expect(Markdowner.to_html("hi @c-_-a_--- test _bye_"))
          .to eq("<p>hi @c-<em>-a</em>— test <em>bye</em></p>\n")
      end
    end
  end

  # bug#209
  it "keeps punctuation inside of auto-generated links when using brackets" do
    expect(Markdowner.to_html("hi <http://example.com/a.> test"))
      .to eq("<p>hi <a href=\"http://example.com/a.\" rel=\"ugc\">" +
            "http://example.com/a.</a> test</p>\n")
  end

  # bug#242
  it "does not expand @ signs inside urls" do
    create(:user, :username => "blahblah")

    expect(Markdowner.to_html("hi http://example.com/@blahblah/ test"))
      .to eq("<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"ugc\">" +
            "http://example.com/@blahblah/</a> test</p>\n")

    expect(Markdowner.to_html("hi [test](http://example.com/@blahblah/)"))
      .to eq("<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"ugc\">" +
        "test</a></p>\n")
  end

  it "correctly adds ugc" do
    expect(Markdowner.to_html("[ex](http://example.com)"))
      .to eq("<p><a href=\"http://example.com\" rel=\"ugc\">" +
            "ex</a></p>\n")

    expect(Markdowner.to_html("[ex](//example.com)"))
      .to eq("<p><a href=\"//example.com\" rel=\"ugc\">" +
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
        "<p><a href=\"#{fake_img_url}\" rel=\"ugc\">#{inner_text}</a></p>\n"
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

    it 'allows image tags' do
      expect(subject).to include '<img'
    end
  end
end
