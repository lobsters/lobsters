require "rails_helper"

describe Story do
  it "should get a short id" do
    s = Story.make!(:title => "hello", :url => "http://example.com/")

    expect(s.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  it "requires a url or a description" do
    expect { Story.make!(:title => "hello", :url => "", :description => "") }.to raise_error

    expect { Story.make!(:title => "hello", :description => "hi", :url => nil) }.to_not raise_error

    expect {
      Story.make!(:title => "hello", :url => "http://ex.com/", :description => nil)
    }.to_not raise_error
  end

  it "does not allow too-short titles" do
    expect { Story.make!(:title => "") }.to raise_error
    expect { Story.make!(:title => "hi") }.to raise_error
    expect { Story.make!(:title => "hello") }.to_not raise_error
  end

  it "does not allow too-long titles" do
    expect { Story.make!(:title => ("hello" * 100)) }.to raise_error
  end

  it "must have at least one tag" do
    expect { Story.make!(:tags_a => nil) }.to raise_error
    expect { Story.make!(:tags_a => ["", " "]) }.to raise_error

    expect { Story.make!(:tags_a => ["", "tag1"]) }.to_not raise_error
  end

  it "removes redundant http port 80 and https port 443" do
    expect(Story.new(url: 'http://example.com:80').url).to eq('http://example.com')
    expect(Story.new(url: 'http://example.com:80/').url).to eq('http://example.com/')
    expect(Story.new(url: 'https://example.com:443').url).to eq('https://example.com')
    expect(Story.new(url: 'https://example.com:443/').url).to eq('https://example.com/')
  end

  it "removes utm_ tracking parameters" do
    expect(Story.new(url: 'http://a.com?a=b').url).to eq('http://a.com?a=b')
    expect(Story.new(url: 'http://a.com?utm_term=track&c=d').url).to eq('http://a.com?c=d')
    expect(Story.new(url: 'http://a.com?a=b&utm_term=track&c=d').url).to eq('http://a.com?a=b&c=d')
  end

  it "checks for invalid urls" do
    expect(Story.new(url: 'http://example.com').tap(&:valid?).errors[:url]).to be_empty

    expect(Story.new(url: 'http://example/').tap(&:valid?).errors[:url]).to_not be_empty
    expect(Story.new(url: 'ftp://example.com/').tap(&:valid?).errors[:url]).to_not be_empty
    expect(Story.new(url: 'http://example.com:123/').tap(&:valid?).errors[:url]).to be_empty
  end

  it "checks for a previously posted story with same url" do
    expect(Story.count).to eq(0)

    Story.make!(:title => "flim flam", :url => "http://example.com/")
    expect(Story.count).to eq(1)

    expect {
      Story.make!(:title => "flim flam 2", :url => "http://example.com/")
    }.to raise_error

    expect(Story.count).to eq(1)

    expect {
      Story.make!(:title => "flim flam 2", :url => "http://www.example.com/")
    }.to raise_error

    expect(Story.count).to eq(1)
  end

  it "parses domain properly" do
    story = Story.new
    {
      "http://example.com": "example.com",
      "https://example.com": "example.com",
      "http://example.com:8000": "example.com",
      "http://example.com:8000/": "example.com",
      "http://www3.example.com/goose": "example.com",
      "http://flub.example.com": "flub.example.com",
    }.each_pair do |url, domain|
      story.url = url
      expect(story.domain).to eq(domain)
    end
  end

  it "has domain straight out of the db, when Rails doesn't use setters" do
    s = Story.make!(url: 'https://example.com/foo.html')
    s = Story.find(s.id)
    expect(s.domain).to eq('example.com')
    s.url = 'http://example.org'
    expect(s.domain).to eq('example.org')
    s.url = 'invalid'
    expect(s.domain).to be_nil
  end

  it "converts a title to a url properly" do
    s = Story.make!(:title => "Hello there, this is a title")
    expect(s.title_as_url).to eq("hello_there_this_is_title")

    s = Story.make!(:title => "Hello _ underscore")
    expect(s.title_as_url).to eq("hello_underscore")

    s = Story.make!(:title => "Hello, underscore")
    expect(s.title_as_url).to eq("hello_underscore")

    s = Story.make(:title => "The One-second War (What Time Will You Die?) ")
    expect(s.title_as_url).to eq("one_second_war_what_time_will_you_die")
  end

  it "is not editable by another non-admin user" do
    u = User.make!

    s = Story.make!(:user_id => u.id)
    expect(s.is_editable_by_user?(u)).to be true

    u = User.make!
    expect(s.is_editable_by_user?(u)).to be false
  end

  it "can fetch its title properly" do
    s = Story.make
    s.fetched_content = File.read(Rails.root + "spec/fixtures/story_pages/1.html")
    expect(s.fetched_attributes[:title]).to eq("B2G demo & quick hack // by Paul Rouget")

    s = Story.make
    s.fetched_content = File.read(Rails.root + "spec/fixtures/story_pages/2.html")
    expect(s.fetched_attributes[:title]).to eq("Google")
  end

  it "does not fetch title with a port specified" do
    expect(Sponge).to_not receive(:new)
    story = Story.new url: 'https://example.com:123/'
    expect(story.fetched_attributes[:title]).to eq('')
  end

  it "sets the url properly" do
    s = Story.make(:title => "blah")
    s.url = "https://factorable.net/"
    s.valid?
    expect(s.url).to eq("https://factorable.net/")
  end

  it "calculates tag changes properly" do
    s = Story.make!(:title => "blah", :tags_a => ["tag1", "tag2"])

    s.tags_a = ["tag2"]
    expect(s.tagging_changes).to eq("tags" => ["tag1 tag2", "tag2"])
  end

  it "logs moderations properly" do
    mod = User.make!(:username => "mod", :is_moderator => true)

    s = Story.make!(:title => "blah", :tags_a => ["tag1", "tag2"],
      :description => "desc")

    s.title = "changed title"
    s.description = nil
    s.tags_a = ["tag1"]

    s.editor = mod
    s.moderation_reason = "because i hate you"
    s.save!

    mod_log = Moderation.last
    expect(mod_log.moderator_user_id).to eq(mod.id)
    expect(mod_log.story_id).to eq(s.id)
    expect(mod_log.reason).to eq("because i hate you")
    expect(mod_log.action).to match(/title from "blah" to "changed title"/)
    expect(mod_log.action).to match(/tags from "tag1 tag2" to "tag1"/)
  end
end
