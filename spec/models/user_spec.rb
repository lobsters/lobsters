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
end
