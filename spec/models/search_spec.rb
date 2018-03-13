require "spec_helper"

describe Search do

  # We need to set up and then teardown the environment
  # outside of the typical RSpec transaction because
  # the search module uses custom SQL that doesn't
  # work inside the transaction
  before(:all) do
    @user = User.make!

    @multi_tag = Story.make!(:title => "multitag term1 t1 t2",
                             :url => "https://example.com/3",
                             :user_id => @user.id,
                             :tags_a => ["tag1", "tag2"])
    @stories = [
      Story.make!(:title => "unique",
                  :url => "https://example.com/unique",
                  :user_id => @user.id,
                  :tags_a => ["tag1"]),
      Story.make!(:title => "term1 domain1",
                  :url => "https://example.com/1",
                  :user_id => @user.id,
                  :tags_a => ["tag1"]),
      Story.make!(:title => "term1 t2",
                  :url => "https://example.com/2",
                  :user_id => @user.id,
                  :tags_a => ["tag2"]),
      @multi_tag,
      Story.make!(:title => "term1 domain2",
                  :url => "https://lobste.rs/1",
                  :user_id => @user.id,
                  :tags_a => ["tag1"]),
    ]
  end

  after(:all) do
    @user.destroy!
    @stories.each { |s| s.destroy! }
  end

  it "can search for stories" do
    search = Search.new
    search.q = "unique"

    search.search_for_user!(@user)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("unique")
  end

  it "can search for multitaged stories" do
    search = Search.new
    search.q = "multitag"

    search.search_for_user!(@user)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("multitag term1 t1 t2")
  end

  it "can search for stories by domain" do
    search = Search.new
    search.q = "term1 domain:lobste.rs"

    search.search_for_user!(@user)

    expect(search.results.length).to eq(1)
    expect(search.results.first.title).to eq("term1 domain2")
  end

  it "can search for stories by tag" do
    search = Search.new
    search.q = "term1 tag:tag1"

    search.search_for_user!(@user)

    expect(search.results.length).to eq(3)

    # Stories with multiple tags should return all the tags
    multi_tag_res = search.results.select do |res|
      res.id == @multi_tag.id
    end

    expect(multi_tag_res.length).to eq(1)
    expect(multi_tag_res.first.sorted_taggings.first.tag.tag).to eq("tag1")
    expect(multi_tag_res.first.sorted_taggings.second.tag.tag).to eq("tag2")
  end

  it "should return only stories with both tags if multiple tags are present" do
    search = Search.new
    search.q = "term1 tag:tag1 tag:tag2"

    search.search_for_user!(@user)

    expect(search.results.length).to eq(1)
  end

  it "can search for stories with only tags" do
    search = Search.new
    search.q = "tag:tag2"

    search.search_for_user!(@user)

    expect(search.results.length).to eq(2)
  end
end
