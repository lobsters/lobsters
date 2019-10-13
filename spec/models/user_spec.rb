require "rails_helper"

describe User do
  it "has a valid username" do
    expect { create(:user, :username => nil) }.to raise_error
    expect { create(:user, :username => "") }.to raise_error
    expect { create(:user, :username => "*") }.to raise_error

    create(:user, :username => "newbie")
    expect { create(:user, :username => "newbie") }.to raise_error
  end

  it "has a valid email address" do
    create(:user, :email => "user@example.com")

    # duplicate
    expect { create(:user, :email => "user@example.com") }.to raise_error

    # bad address
    expect { create(:user, :email => "user@") }.to raise_error

    # address too long
    expect(build(:user, :email => "a" * 95 + "@example.com")).to_not be_valid
  end

  it "has a limit on the password reset token field" do
    user = build(:user, :password_reset_token => "a" * 100)
    user.valid?
    expect(user.errors[:password_reset_token]).to eq(['is too long (maximum is 75 characters)'])
  end

  it "has a limit on the session token field" do
    user = build(:user, :session_token => "a" * 100)
    user.valid?
    expect(user.errors[:session_token]).to eq(['is too long (maximum is 75 characters)'])
  end

  it "has a limit on the about field" do
    user = build(:user, :about => "a" * 16_777_218)
    user.valid?
    expect(user.errors[:about]).to eq(['is too long (maximum is 16777215 characters)'])
  end

  it "has a limit on the rss token field" do
    user = build(:user, :rss_token => "a" * 100)
    user.valid?
    expect(user.errors[:rss_token]).to eq(['is too long (maximum is 75 characters)'])
  end

  it "has a limit on the mailing list token field" do
    user = build(:user, :mailing_list_token => "a" * 100)
    user.valid?
    expect(user.errors[:mailing_list_token]).to eq(['is too long (maximum is 75 characters)'])
  end

  it "has a limit on the banned reason field" do
    user = build(:user, :banned_reason => "a" * 300)
    user.valid?
    expect(user.errors[:banned_reason]).to eq(['is too long (maximum is 200 characters)'])
  end

  it "has a limit on the disabled invite reason field" do
    user = build(:user, :disabled_invite_reason => "a" * 300)
    user.valid?
    expect(user.errors[:disabled_invite_reason]).to eq(['is too long (maximum is 200 characters)'])
  end

  it "has a valid homepage" do
    expect(build(:user, :homepage => "https://lobste.rs")).to be_valid
    expect(build(:user, :homepage => "https://lobste.rs/w00t")).to be_valid
    expect(build(:user, :homepage => "https://lobste.rs/w00t.path")).to be_valid
    expect(build(:user, :homepage => "https://lobste.rs/w00t")).to be_valid
    expect(build(:user, :homepage => "https://ሙዚቃ.et")).to be_valid
    expect(build(:user, :homepage => "http://lobste.rs/ሙዚቃ")).to be_valid
    expect(build(:user, :homepage => "http://www.lobste.rs/")).to be_valid

    expect(build(:user, :homepage => "http://")).to_not be_valid
    expect(build(:user, :homepage => "http://notld")).to_not be_valid
    expect(build(:user, :homepage => "http://notld/w00t.path")).to_not be_valid
    expect(build(:user, :homepage => "ftp://invalid.protocol")).to_not be_valid
  end

  it "authenticates properly" do
    u = create(:user, :password => "hunter2")

    expect(u.password_digest.length).to be > 20

    expect(u.authenticate("hunter2")).to eq(u)
    expect(u.authenticate("hunteR2")).to be false
  end

  it "gets an error message after registering banned name" do
    expect { create(:user, :username => "admin") }
           .to raise_error("Validation failed: Username is not permitted")
  end

  it "shows a user is banned or not" do
    u = create(:user, :banned)
    user = create(:user)
    expect(u.is_banned?).to be true
    expect(user.is_banned?).to be false
  end

  it "shows a user is active or not" do
    u = create(:user, :banned)
    user = create(:user)
    expect(u.is_active?).to be false
    expect(user.is_active?).to be true
  end

  it "shows a user is recent or not" do
    user = create(:user, :created_at => Time.current)
    u = create(:user, :created_at => Time.current - 8.days)
    expect(user.is_new?).to be true
    expect(u.is_new?).to be false
  end

  it "unbans a user" do
    u = create(:user, :banned)
    expect(u.unban_by_user!(User.first)).to be true
  end

  it "tells if a user is a heavy self promoter" do
    u = create(:user)

    expect(u.is_heavy_self_promoter?).to be false

    create(:story, :title => "ti1", :url => "https://a.com/1", :user_id => u.id,
      :user_is_author => true)
    # require at least 2 stories to be considered heavy self promoter
    expect(u.is_heavy_self_promoter?).to be false

    create(:story, :title => "ti2", :url => "https://a.com/2", :user_id => u.id,
      :user_is_author => true)
    # 100% of 2 stories
    expect(u.is_heavy_self_promoter?).to be true

    create(:story, :title => "ti3", :url => "https://a.com/3", :user_id => u.id,
      :user_is_author => false)
    # 66.7% of 3 stories
    expect(u.is_heavy_self_promoter?).to be true

    create(:story, :title => "ti4", :url => "https://a.com/4", :user_id => u.id,
      :user_is_author => false)
    # 50% of 4 stories
    expect(u.is_heavy_self_promoter?).to be false
  end
end
