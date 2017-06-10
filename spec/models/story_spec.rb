require "spec_helper"

describe Story do
  it "should get a short id" do
    s = Story.make!(:title => "hello", :url => "http://example.com/")

    expect(s.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  it "requires a url or a description" do
    expect { Story.make!(:title => "hello", :url => "",
      :description => "") }.to raise_error

    expect { Story.make!(:title => "hello", :description => "hi", :url => nil)
      }.to_not raise_error

    expect { Story.make!(:title => "hello", :url => "http://ex.com/",
      :description => nil) }.to_not raise_error
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
    expect { Story.make!(:tags_a => [ "", " " ]) }.to raise_error

    expect { Story.make!(:tags_a => [ "", "tag1" ]) }.to_not raise_error
  end

  it "checks for invalid urls" do
    expect { Story.make!(:title => "test", :url => "http://gooses.com/")
      }.to_not raise_error

    expect { Story.make!(:title => "test", url => "ftp://gooses/")
      }.to raise_error
  end

  it "checks for a previously posted story with same url" do
    expect(Story.count).to eq(0)

    Story.make!(:title => "flim flam", :url => "http://example.com/")
    expect(Story.count).to eq(1)

    expect { Story.make!(:title => "flim flam 2",
      :url => "http://example.com/") }.to raise_error

    expect(Story.count).to eq(1)

    expect { Story.make!(:title => "flim flam 2",
      :url => "http://www.example.com/") }.to raise_error

    expect(Story.count).to eq(1)
  end

  it "parses domain properly" do
    s = Story.make!(:url => "http://example.com")
    expect(s.domain).to eq("example.com")

    s = Story.make!(:url => "http://www3.example.com/goose")
    expect(s.domain).to eq("example.com")

    s = Story.make!(:url => "http://flub.example.com")
    expect(s.domain).to eq("flub.example.com")
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
    s.fetched_content = File.read(Rails.root +
      "spec/fixtures/story_pages/1.html")
    expect(s.fetched_attributes[:title]).to eq("B2G demo & quick hack // by Paul Rouget")

    s = Story.make
    s.fetched_content = File.read(Rails.root +
      "spec/fixtures/story_pages/2.html")
    expect(s.fetched_attributes[:title]).to eq("Google")
  end

  it "sets the url properly" do
    s = Story.make(:title => "blah")
    s.url = "https://factorable.net/"
    s.valid?
    expect(s.url).to eq("https://factorable.net/")
  end

  it "calculates tag changes properly" do
    s = Story.make!(:title => "blah", :tags_a => [ "tag1", "tag2" ])

    s.tags_a = [ "tag2" ]
    expect(s.tagging_changes).to eq({ "tags" => [ "tag1 tag2", "tag2" ] })
  end

  it "logs moderations properly" do
    mod = User.make!(:username => "mod", :is_moderator => true)

    s = Story.make!(:title => "blah", :tags_a => [ "tag1", "tag2" ],
      :description => "desc")

    s.title = "changed title"
    s.description = nil
    s.tags_a = [ "tag1" ]

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
