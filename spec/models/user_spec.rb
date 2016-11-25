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
    u.unban_by_user!(User.first).should == true
  end

  describe 'Blocking users' do
    subject(:user) do
      User.create(username: 'user_1',
                  email: 'user@mail.com',
                  password: '12345678',
                  password_confirmation: '12345678')
    end

    subject(:user_2) do
      User.create(username: 'user_2',
                           email: 'user2@mail.com',
                           password: '12345678',
                           password_confirmation: '12345678')
    end

    describe '#has_blocked?' do
      it 'takes one argument only' do
        expect { user.has_blocked? }.to raise_error
      end

      it 'returns true if  a user is on the block list' do
        user.privately_block user_2
        expect(user.has_blocked?(user_2)).to be_truthy
      end

      it 'returns false if a user is not on the block list' do
        expect(user.has_blocked?(user_2)).to be_falsey
      end
    end

    describe '#privately_block_user' do
      it 'takes one argument only' do
        expect { user.privately_block }.to raise_error
      end

      it 'adds another user to a blocked user list' do
        user.privately_block(user_2)

        result = !!user.blocked_users.find do |o|
          o.blocked_user_id == user_2.id
        end

        expect(result).to be_truthy
      end
    end

    describe '#unblock' do
      it 'takes one argument only' do
        expect { user.unblock }.to raise_error
      end

      it 'removes a user from the blocked user list' do
        user.privately_block(user_2)
        expect(user.has_blocked?(user_2)).to be_truthy

        user.unblock(user_2)
        expect(user.reload.has_blocked?(user_2)).to be_falsey
      end
    end
  end
end
