require 'spec_helper'

describe BlockedUser do
  let(:blocked_user_id) { 1 }
  let(:user_id) { 2 }

  subject(:blocked_user) { BlockedUser.new(blocked_user_id: blocked_user_id, user_id: user_id) }

  it { expect(blocked_user).to be_valid }

  describe '#blocked_user_id' do
    let(:blocked_user_id) { nil }

    it 'should be present when creating a blocked user' do
      expect(blocked_user).to be_invalid
    end

    it 'should be uniquely scoped to a user' do
      blocked_user.save
      expect(blocked_user.dup).to be_invalid
    end

    context 'when the blocked_user_id attribute is the same as the user_id' do
      let(:blocked_user_id) { 2 }

      it 'should not have the same value as the user id' do
        expect(blocked_user).to be_invalid
      end
    end

  end

  describe '#user_id' do
    let(:user_id) { nil }

    it 'should be present when creating a blocked user' do
      expect(blocked_user).to be_invalid
    end

    context 'when the user_id attribute is the same as the blocked_user_id attribute' do
      let(:user_id) { 1 }

      it 'should not have the same value as the blocked_user_id' do
        expect(blocked_user).to be_invalid
      end
    end
  end
end