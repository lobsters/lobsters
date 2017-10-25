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

    expect(u.password_digest.length).to be > 20

    expect(u.authenticate("hunter2")).to eq(u)
    expect(u.authenticate("hunteR2")).to be false
  end

  it "gets an error message after registering banned name" do
    expect { User.make!(:username => "admin") }.to raise_error("Validation failed: Username is not permitted")
  end

  it "shows a user is banned or not" do
    u = User.make!(:banned)
    user = User.make!
    expect(u.is_banned?).to be true
    expect(user.is_banned?).to be false
  end

  it "shows a user is active or not" do
    u = User.make!(:banned)
    user = User.make!
    expect(u.is_active?).to be false
    expect(user.is_active?).to be true
  end

  it "shows a user is recent or not" do
    user = User.make!(:created_at => Time.now)
    u = User.make!(:created_at => Time.now - 8.days)
    expect(user.is_new?).to be true
    expect(u.is_new?).to be false
  end

  it "unbans a user" do
    u = User.make!(:banned)
    expect(u.unban_by_user!(User.first)).to be true
  end

  it "tells if a user is a heavy self promoter" do
    u = User.make!

    expect(u.is_heavy_self_promoter?).to be false

    Story.make!(:title => "ti1", :url => "https://a.com/1", :user_id => u.id,
      :user_is_author => true)
    # require at least 2 stories to be considered heavy self promoter
    expect(u.is_heavy_self_promoter?).to be false

    Story.make!(:title => "ti2", :url => "https://a.com/2", :user_id => u.id,
      :user_is_author => true)
    # 100% of 2 stories
    expect(u.is_heavy_self_promoter?).to be true

    Story.make!(:title => "ti3", :url => "https://a.com/3", :user_id => u.id,
      :user_is_author => false)
    # 66.7% of 3 stories
    expect(u.is_heavy_self_promoter?).to be true

    Story.make!(:title => "ti4", :url => "https://a.com/4", :user_id => u.id,
      :user_is_author => false)
    # 50% of 4 stories
    expect(u.is_heavy_self_promoter?).to be false
  end
end
