# typed: false

require "rails_helper"

describe ApplicationHelper do
  describe "excerpt_fragment_around_link" do
    it "strips HTML tags besides the link" do
      comment = create(:comment, comment: "I **love** [example](https://example.com) so much")
      expect(comment.markeddown_comment).to include("strong") # the double star
      excerpt = helper.excerpt_fragment_around_link(comment.markeddown_comment, "https://example.com")
      expect(excerpt).to_not include("strong")
      expect(excerpt).to start_with("I love")    # text before
      expect(excerpt).to include("example.com")  # link href
      expect(excerpt).to end_with("so much")     # text after
    end

    it "strips HTML tags wrapping the link" do
      comment = create(:comment, comment: "I **love [example](https://example.com)**")
      expect(comment.markeddown_comment).to include("strong") # the double star
      excerpt = helper.excerpt_fragment_around_link(comment.markeddown_comment, "https://example.com")
      expect(excerpt).to_not include("strong")
      expect(excerpt).to include("example.com")
    end

    it "excerpts even in multiple nesting" do
      comment = create(:comment, comment: "See:\n\n * an _[example](https://example.com)_")
      expect(comment.markeddown_comment).to include("<li>")
      expect(comment.markeddown_comment).to include("<em>")
      excerpt = helper.excerpt_fragment_around_link(comment.markeddown_comment, "https://example.com")
      expect(excerpt).to_not include("li")
      expect(excerpt).to_not include("em")
      expect(excerpt).to include("example.com")
    end

    it "displays a few words around links in comments" do
      comment = create(:comment, comment: "This reminds me of [a great site](https://example.com) with more info. #{Faker::Lorem.sentences(number: 30).join(" ")}")
      excerpt = helper.excerpt_fragment_around_link(comment.markeddown_comment, "https://example.com")
      expect(excerpt.split.length).to be < 20
    end

    it "strips unpaired, invalid HTML tags" do
      html = '<p>i <strong>love <a href="https://example.com">example</a></p>'
      excerpt = helper.excerpt_fragment_around_link(html, "https://example.com")
      expect(excerpt).to_not include("strong")
      expect(excerpt).to include("example.com")
    end

    it "returns the first few words if the link is not present" do
      html = "Hello world. #{Faker::Lorem.sentences(number: 30).join(" ")} Removed."
      excerpt = helper.excerpt_fragment_around_link(html, "https://example.com")
      expect(excerpt).to_not include("Removed")
      expect(excerpt).to start_with("Hello world")
    end
  end

  describe "#page_numbers_for_pagination" do
    it "returns the right number of pages" do
      expect(helper.page_numbers_for_pagination(10, 1))
        .to eq([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

      expect(helper.page_numbers_for_pagination(20, 1))
        .to eq([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, "...", 20])

      expect(helper.page_numbers_for_pagination(25, 1))
        .to eq([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, "...", 25])

      expect(helper.page_numbers_for_pagination(25, 10))
        .to eq([1, "...", 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, "...", 25])

      expect(helper.page_numbers_for_pagination(25, 20))
        .to eq([1, "...", 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
    end
  end

  describe "#page_count" do
    it "returns the right number of pages" do
      expect(page_count(49, 50)).to eq(1)
      expect(page_count(50, 50)).to eq(1)
      expect(page_count(51, 50)).to eq(2)
      expect(page_count(99, 50)).to eq(2)
      expect(page_count(100, 50)).to eq(2)
    end
  end
end
