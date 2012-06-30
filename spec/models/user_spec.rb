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
    expect { User.make!(:email => "user@example.com") }.to raise_error
  end

  it "authenticates properly" do
    u = User.make!(:password => "pilgrim")

    u.password_digest.length.should > 20

    u.authenticate("pilgrim").should == u
    u.authenticate("pilgriM").should == false
  end
end
