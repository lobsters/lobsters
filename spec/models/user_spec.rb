require "spec_helper"

describe User do
  it "has a valid username" do
    expect { User.make!(:username => nil) }.to raise_error
    expect { User.make!(:username => "") }.to raise_error
    expect { User.make!(:username => "*") }.to raise_error

    User.make!(:username => "test")
    expect { User.make!(:username => "test") }.to raise_error
  end

  it "has a valid email address" do
    User.make!(:email => "user@example.com")

    # duplicate
    expect { User.make!(:email => "user@example.com") }.to raise_error

    # bad address
    expect { User.make!(:email => "user@") }.to raise_error
  end

  it "authenticates properly" do
    u = User.make!(:password => "hunter2")

    u.password_digest.length.should > 20

    u.authenticate("hunter2").should == u
    u.authenticate("hunteR2").should == false
  end

  it "gets an error message after registering banned name" do
    expect { User.make!(:username => "admin") }.to raise_error("Validation failed: Username is not permitted")
  end

  it "shows a user is banned or not" do
    u = User.make!(:banned)
    user = User.make!
    u.is_banned?.should == true
    user.is_banned?.should == false
  end

  it "shows a user is active or not" do
    u = User.make!(:banned)
    user = User.make!
    u.is_active?.should == false
    user.is_active?.should == true
  end

  it "shows a user is recent or not" do
    user = User.make!(:created_at => Time.now)
    u = User.make!(:created_at => Time.now - 8.days)
    user.is_new?.should == true
    u.is_new?.should == false
  end

  it "unbans a user" do
    u = User.make!(:banned)
    u.unban!.should be_true
  end

  it "show a user can downvote" do
    user = User.make!(:created_at => Time.now)
    u = User.make!(:created_at => Time.now - 8.days)
    user.can_downvote?.should == false
    u.can_downvote?.should == true
  end

  it "can delete a user" do
    u = User.make!
    u.delete!
    u.deleted_at.should be_true
  end

  it "username to params" do
    u = User.make!
    u.to_param.should == u.username
  end

  it "show a user's about section with links" do
    u = User.make!(:about => "http://www.example.com")
    u.linkified_about.should == "<a rel=\"nofollow\" href=\"http://www.example.com\">http://www.example.com</a></p>\n"
  end

  it "show the count of stories submitted" do
    u = User.make!
    s = Story.make!(:user_id => u.id)
    u.stories_submitted_count.should == 1
  end

end
