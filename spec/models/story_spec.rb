require "spec_helper"

describe Story do
  it "should get a short id" do
    s = Story.make!(:title => "hello", :url => "http://example.com/")

    s.short_id.should match(/^\A[a-zA-Z0-9]{1,10}\z/)
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
    Story.count.should == 0

    Story.make!(:title => "flim flam", :url => "http://example.com/")
    Story.count.should == 1

    expect { Story.make!(:title => "flim flam 2",
      :url => "http://example.com/") }.to raise_error

    Story.count.should == 1

    expect { Story.make!(:title => "flim flam 2",
      :url => "http://www.example.com/") }.to raise_error

    Story.count.should == 1
  end

  it "parses domain properly" do
    s = Story.make!(:url => "http://example.com")
    s.domain.should == "example.com"

    s = Story.make!(:url => "http://www3.example.com/goose")
    s.domain.should == "example.com"

    s = Story.make!(:url => "http://flub.example.com")
    s.domain.should == "flub.example.com"
  end

  it "converts a title to a url properly" do
    s = Story.make!(:title => "Hello there, this is a title")
    s.title_as_url.should == "hello_there_this_is_title"

    s = Story.make!(:title => "Hello _ underscore")
    s.title_as_url.should == "hello_underscore"

    s = Story.make!(:title => "Hello, underscore")
    s.title_as_url.should == "hello_underscore"

    s = Story.make(:title => "The One-second War (What Time Will You Die?) ")
    s.title_as_url.should == "one_second_war_what_time_will_you_die"
  end

  it "is not editable by another non-admin user" do
    u = User.make!

    s = Story.make!(:user_id => u.id)
    s.is_editable_by_user?(u).should == true

    u = User.make!
    s.is_editable_by_user?(u).should == false
  end

  it "can fetch its title properly" do
    s = Story.make
    s.fetched_content = File.read(Rails.root +
      "spec/fixtures/story_pages/1.html")
    s.fetched_attributes[:title].should == "B2G demo & quick hack // by Paul Rouget"

    s = Story.make
    s.fetched_content = File.read(Rails.root +
      "spec/fixtures/story_pages/2.html")
    s.fetched_attributes[:title].should == "Google"
  end

  it "sets the url properly" do
    s = Story.make(:title => "blah")
    s.url = "https://factorable.net/"
    s.valid?
    s.url.should == "https://factorable.net/"
  end

  it "calculates tag changes properly" do
    s = Story.make!(:title => "blah", :tags_a => [ "tag1", "tag2" ])

    s.tags_a = [ "tag2" ]
    s.tagging_changes.should == { "tags" => [ "tag1 tag2", "tag2" ] }
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
    mod_log.moderator_user_id.should == mod.id
    mod_log.story_id.should == s.id
    mod_log.reason.should == "because i hate you"
    mod_log.action.should match(/title from "blah" to "changed title"/)
    mod_log.action.should match(/tags from "tag1 tag2" to "tag1"/)
  end
end
