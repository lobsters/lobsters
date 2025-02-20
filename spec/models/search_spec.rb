# typed: false

require "rails_helper"

describe Search do
  # We need to set up and then teardown the environment
  # outside of the typical RSpec transaction because
  # the search module uses custom SQL that doesn't
  # work inside the transaction
  before(:all) do
    @alice = create(:user, username: "alice")
    @bob = create(:user, username: "bob")

    @multi_tag = create(:story, title: "multitag term1 t1 t2",
      url: "https://example.com/3",
      user_id: @alice.id,
      tags: Tag.where(tag: ["tag1", "tag2"]))
    @stories = [
      create(:story, title: "unique",
        url: "https://example.com/unique",
        user_id: @bob.id,
        tags: Tag.where(tag: ["tag1"])),
      create(:story, title: "term1 domain1",
        url: "https://example.com/1",
        user_id: @alice.id,
        tags: Tag.where(tag: ["tag1"])),
      create(:story, title: "term1 t2",
        url: "https://example.com/2",
        user_id: @bob.id,
        tags: Tag.where(tag: ["tag2"])),
      @multi_tag,
      create(:story, title: "term1 domain2",
        url: "https://lobste.rs/1",
        user_id: @alice.id,
        tags: Tag.where(tag: ["tag1"]))
    ]
    @stories.each do |s|
      StoryText.create id: s.id, title: s.title, description: s.description
    end
    @comments = [
      create(:comment, comment: "comment0",
        story_id: @multi_tag.id,
        user_id: @bob.id),
      create(:comment, comment: "comment1",
        story_id: @stories[0].id,
        user_id: @alice.id),
      create(:comment, comment: "comment2",
        story_id: @stories[1].id,
        user_id: @alice.id),
      create(:comment, comment: "comment3",
        story_id: @stories[2].id,
        user_id: @bob.id),
      create(:comment, comment: "comment4 comment",
        story_id: @stories[4].id,
        user_id: @bob.id)
    ]
  end

  after(:all) do
    @comments.each(&:destroy!)
    @stories.flat_map(&:votes).each(&:destroy!)
    @stories.each(&:destroy!)
    @alice&.destroy!
    @bob&.destroy!
  end

  it "returns nothing when initialized empty" do
    search = Search.new({}, nil)

    # test is a bit brittle by coupling to the way the caching couples to the perform! dispatcher,
    # but add db-query-matchers gem if test gets flaky
    expect(search).to_not receive(:perform_story_search!)
    expect(search).to_not receive(:perform_comment_search!)

    expect(search.results.length).to eq(0)
  end

  it "doesn't permit sql injection" do
    %w[' " % \\' \\" \\\\' \\\\"].each do |esc|
      [
        # stories
        {what: "stories", q: "term#{esc}"},
        {what: "stories", q: "\"term#{esc}\""},
        {what: "stories", q: "domain:foo#{esc}"},
        {what: "stories", q: "submitter:alice{esc}"},
        {what: "stories", q: "submitter:@bob{esc}"},
        {what: "stories", q: "tag:foo#{esc}"},
        {what: "stories", q: "title:titl#{esc}"},
        {what: "stories", q: "title:\"multi#{esc} titl\""},
        {what: "stories", q: "term#{esc}"},
        {what: "stories", q: "term", order: "newest#{esc}"},
        {what: "stories", q: "term", page: "2#{esc}"},
        {what: "stories#{esc}", q: "term"},
        {what: "stories", q: "o'caml"},
        {what: "stories", q: "can't"},
        {what: "stories", q: "term 'two apostrophes'"},
        {what: "stories", q: "'go-sqlite'"},
        # some real attack attempts:
        {what: "stories", q: "tag:formalmethods tag:testing'' ORDER BY 1-- BjzD"},
        {what: "stories", q: "tag:formalmethods tag:testing'fcvzLp<'\">UkDPPc"},
        {what: "stories", q: "tag:formalmethods tag:testing') AND EXTRACTVALUE(4050,CONCAT(0x5c,0x7170787171,(SELECT (ELT(4050=4050,1))),0x71627a6b71)) AND ('pDUW'='pDUW"},
        # comments
        {what: "comments", q: "term#{esc}"},
        {what: "comments", q: "\"term#{esc}\""},
        {what: "comments", q: "domain:foo#{esc}"},
        {what: "comments", q: "submitter:carol{esc}"},
        {what: "comments", q: "submitter:@dave{esc}"},
        {what: "comments", q: "tag:foo#{esc}"},
        {what: "comments", q: "title:titl#{esc}"},
        {what: "comments", q: "title:\"multi#{esc} titl\""},
        {what: "comments", q: "term#{esc}"},
        {what: "comments", q: "o'caml"},
        {what: "comments", q: "can't"},
        {what: "comments", q: "c++"},
        {what: "comments", q: "\"you can't\""},
        {what: "comments", q: "term", order: "newest#{esc}"},
        {what: "comments", q: "term", page: "2#{esc}"},
        {what: "comments#{esc}", q: "term"}
      ].each do |params|
        # implicit assertion that no error was thrown for invalid SQL
        expect(Search.new(params, nil).results.length).to eq(0)
      end
    end
  end

  # + is the boolean mode operator meaning 'required'
  it "doesn't error on odd real searches with punctuation" do
    [
      {q: "c++"},
      {q: "sudo-rs"},
      {q: "pi-hole"},
      {q: "header X-Powered-By: Express"},
      {q: "snake_case"}
    ].each do |params|
      search = Search.new(params, @alice)

      expect(search.results_count).to be_an_instance_of(Integer)
    end
  end

  it "can search titles for stories" do
    search = Search.new({q: "unique", what: "stories"}, @alice)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("unique")
  end

  it "can search for multitagged stories" do
    search = Search.new({q: "multitag", what: "stories"}, @alice)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("multitag term1 t1 t2")
  end

  it "can search for stories by domain" do
    search = Search.new({q: "term1 domain:lobste.rs", what: "stories"}, @alice)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("term1 domain2")
  end

  it "can search for stories by submitter" do
    search = Search.new({q: "submitter:bob", what: "stories"}, nil)

    expect(search.results.length).to eq(2)
    expect(search.results.map(&:title).sort).to eq(["term1 t2", "unique"])
  end

  it "can search for stories by tag" do
    search = Search.new({q: "term1 tag:tag1", what: "stories"}, @alice)

    expect(search.results.length).to eq(3)

    # It's easy to search tags in a way that Rails thinks satisfies the preload request for
    # story.tags, causing stories to only have the searched-for tags
    multi_tag_res = search.results.select { |res| res.id == @multi_tag.id }
    expect(multi_tag_res.length).to eq(1)
    expect(multi_tag_res.first.tags.map(&:tag).sort).to eq(["tag1", "tag2"])
  end

  it "should return only stories with both tags if multiple tags are present" do
    search = Search.new({q: "term1 tag:tag1 tag:tag2", what: "stories"}, @alice)

    expect(search.results.length).to eq(1)
  end

  it "can search for stories with only tags" do
    search = Search.new({q: "tag:tag2", what: "stories"}, @alice)

    expect(search.results.length).to eq(2)
  end

  it "can search for stories by title" do
    search = Search.new({q: "title:unique", what: "stories"}, @alice)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("unique")
  end

  it "can search for stories by title with multiple words" do
    search = Search.new({q: 'title:"term1 t2"', what: "stories"}, @alice)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("term1 t2")
  end

  it "can search for stories by url" do
    search = Search.new({q: "term1 https://lobste.rs/1", what: "stories"}, @alice)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("term1 domain2")
  end

  it "can search for comments" do
    search = Search.new({q: "comment1", what: "comments"}, @alice)

    expect(search.results).to include(@comments[1])
  end

  it "can search for comments with a quoted term" do
    search = Search.new({q: '"comment1"', what: "comments"}, @alice)
    expect(search.results.to_a).to eq([@comments[1]])
  end

  it "can search multi-word terms" do
    search = Search.new({q: '"comment4 comment"', what: "comments"}, @alice)
    expect(search.results).to eq([@comments[4]])
  end

  it "can search multi-word requiring all terms in order, not an OR search" do
    search = Search.new({q: '"comment1 comment2"', what: "comments"}, @alice)
    expect(search.results).to be_empty
  end

  it "prevents SQL injection in multi-word quoted searches" do
    search = Search.new({q: '"comment1" OR 1=1--', what: "comments"}, @alice)
    expect(search.results.to_a).to eq([@comments[1]])

    search = Search.new({q: '"comment1"\'" OR 1=1--', what: "comments"}, @alice)
    expect(search.results.to_a).to eq([@comments[1]])

    search = Search.new({q: '"comment1\'" OR 1=1--', what: "comments"}, @alice)
    expect(search.results.to_a).to eq([@comments[1]])
  end

  it "can search for comments by tag" do
    search = Search.new({q: "comment2 tag:tag1", what: "comments"}, @alice)

    expect(search.results).to include(@comments[2])
    expect(search.results).not_to include(@comments[3])
  end

  it "can search for comments with only tags" do
    search = Search.new({q: "tag:tag1", what: "comments"}, @alice)

    expect(search.results).to include(@comments[2])
    expect(search.results).not_to include(@comments[3])
  end

  it "should only return comments matching all tags if multiple are present" do
    search = Search.new({q: "tag:tag1 tag:tag2", what: "comments"}, @alice)

    expect(search.results).to eq([@comments[0]])
  end

  it "should only return comments with stories in domain if domain present" do
    search = Search.new({q: "domain:lobste.rs", what: "comments"}, @alice)

    expect(search.results).to include(@comments[4])
    expect(search.results).not_to include(@comments[3])
  end

  it "can search for comments by url" do
    search = Search.new({q: "comment4 https://lobste.rs/1", what: "comments"}, @alice)

    expect(search.results).to eq([@comments[4]])
  end

  it "can search for comments by story title" do
    search = Search.new({q: "comment4 title:domain2", what: "comments"}, @alice)

    expect(search.results).to eq([@comments[4]])
  end

  it "can search for comments by story submitter" do
    search = Search.new({q: "submitter:bob", what: "comments"}, nil)

    expect(search.results.length).to eq(2)
  end

  it "can search for comments by commenter" do
    search = Search.new({q: "commenter:bob", what: "comments"}, nil)

    expect(search.results.length).to eq(3)
  end

  describe "#flatten_title" do
    it "flattens multiword searches to single sql term" do
      s = Search.new({}, nil)
      expect(s.flatten_title({quoted: [{term: "cool"}, {term: "beans"}]})).to eq("\"cool beans\"")
    end

    it "doesn't permit sql injection" do
      s = Search.new({}, nil)
      expect(s.flatten_title({term: "as'df"})).to eq("as\\'df")
      expect(s.flatten_title({term: "hj\"kl"})).to eq("hj\\\"kl")
      expect(s.flatten_title({quoted: [{term: "cat'"}, {term: "scare"}]})).to eq("\"cat\\' scare\"")
    end
  end

  describe "#strip_operators" do
    it "doesn't permit sql injection" do
      s = Search.new({}, nil)
      expect(s.strip_operators("as'df")).to eq("as\\'df")
      expect(s.strip_operators("hj\"kl")).to eq("hj kl")
      expect(s.strip_operators("li%ke")).to eq("li ke")
      expect(s.strip_operators("\"blah\"")).to eq("blah")
    end
  end

  describe "#strip_short_terms" do
    it "removes short words that mariadb would ignore" do
      s = Search.new({}, nil)
      # removes both 1 and 2 char terms
      expect(s.strip_short_terms("i")).to eq("")
      expect(s.strip_short_terms("do")).to eq("")
      expect(s.strip_short_terms("can't")).to eq("can't")
      expect(s.strip_short_terms("o'caml")).to eq("o'caml")
      expect(s.strip_short_terms("c++")).to eq("c++")
    end
  end
end
