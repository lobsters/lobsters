require "rails_helper"

describe Search do
  # We need to set up and then teardown the environment
  # outside of the typical RSpec transaction because
  # the search module uses custom SQL that doesn't
  # work inside the transaction
  before(:all) do
    @user = create(:user)

    @multi_tag = create(:story, :title => "multitag term1 t1 t2",
                             :url => "https://example.com/3",
                             :user_id => @user.id,
                             :tags_a => ["tag1", "tag2"])
    @stories = [
      create(:story, :title => "unique",
                  :url => "https://example.com/unique",
                  :user_id => @user.id,
                  :tags_a => ["tag1"]),
      create(:story, :title => "term1 domain1",
                  :url => "https://example.com/1",
                  :user_id => @user.id,
                  :tags_a => ["tag1"]),
      create(:story, :title => "term1 t2",
                  :url => "https://example.com/2",
                  :user_id => @user.id,
                  :tags_a => ["tag2"]),
      @multi_tag,
      create(:story, :title => "term1 domain2",
                  :url => "https://lobste.rs/1",
                  :user_id => @user.id,
                  :tags_a => ["tag1"]),
    ]
    @comments = [
      create(:comment, :comment => "comment0",
                    :story_id => @multi_tag.id,
                    :user_id => @user.id),
      create(:comment, :comment => "comment1",
                    :story_id => @stories[0].id,
                    :user_id => @user.id),
      create(:comment, :comment => "comment2",
                    :story_id => @stories[1].id,
                    :user_id => @user.id),
      create(:comment, :comment => "comment3",
                    :story_id => @stories[2].id,
                    :user_id => @user.id),
      create(:comment, :comment => "comment4",
                    :story_id => @stories[4].id,
                    :user_id => @user.id),
    ]
  end

  after(:all) do
    @comments.each(&:destroy!)
    @stories.flat_map(&:votes).each(&:destroy!)
    @stories.each(&:destroy!)
    @user.destroy! if @user
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
    expect(multi_tag_res.first.tags.first.tag).to eq("tag1")
    expect(multi_tag_res.first.tags.second.tag).to eq("tag2")
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

  it "can search for comments" do
    search = Search.new
    search.q = "comment1"
    search.what = "comments"

    search.search_for_user!(@user)

    expect(search.results).to include(@comments[1])
  end
  it "can search for comments by tag" do
    search = Search.new
    search.q = "comment2 comment3 tag:tag1"
    search.what = "comments"

    search.search_for_user!(@user)

    expect(search.results).to include(@comments[2])
    expect(search.results).not_to include(@comments[3])
  end
  it "can search for comments with only tags" do
    search = Search.new
    search.q = "tag:tag1"
    search.what = "comments"

    search.search_for_user!(@user)

    expect(search.results).to include(@comments[2])
    expect(search.results).not_to include(@comments[3])
  end
  it "should only return comments matching all tags if multiple are present" do
    search = Search.new
    search.q = "tag:tag1 tag:tag2"
    search.what = "comments"

    search.search_for_user!(@user)

    expect(search.results).to eq([@comments[0]])
  end

  it "should only return comments with stories in domain if domain present" do
    search = Search.new
    search.q = "comment3 comment4 domain:lobste.rs"
    search.what = "comments"

    search.search_for_user!(@user)

    expect(search.results).to include(@comments[4])
    expect(search.results).not_to include(@comments[3])
  end
end
