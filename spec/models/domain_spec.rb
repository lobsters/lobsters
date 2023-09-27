# typed: false

require "rails_helper"

RSpec.describe Domain, type: :model do
  describe "ban" do
    let(:user) { create(:user) }
    let(:domain) { create(:domain) }

    before do
      domain.ban_by_user_for_reason!(user, "Test reason")
    end

    describe "should be banned" do
      it "has correct banned_at" do
        expect(domain.banned_at).not_to be nil
      end

      it "has correct banned_by_user_id" do
        expect(domain.banned_by_user_id).to eq user.id
      end

      it "has correct banned_reason" do
        expect(domain.banned_reason).to eq "Test reason"
      end
    end

    describe "should have moderation" do
      before do
        @moderation = Moderation.find_by(domain: domain)
      end

      it "moderation should be created" do
        expect(@moderation).not_to be nil
      end

      it "has correct moderator_user_id" do
        expect(@moderation.moderator_user_id).to eq user.id
      end

      it "has correct action" do
        expect(@moderation.action).to eq "Banned"
      end

      it "has correct reason" do
        expect(@moderation.reason).to eq "Test reason"
      end
    end
  end

  describe "unban" do
    let(:user) { create(:user) }
    let(:domain) {
      create(
        :domain,
        banned_at: Time.current,
        banned_by_user_id: user.id,
        banned_reason: "test reason"
      )
    }

    before do
      domain.unban_by_user_for_reason!(user, "Test reason")
    end

    describe "should be unbanned" do
      it "has empty banned_at" do
        expect(domain.banned_at).to be nil
      end

      it "has empty banned_by_user_id" do
        expect(domain.banned_by_user_id).to be nil
      end

      it "has empty banned_reason" do
        expect(domain.banned_reason).to be nil
      end
    end

    describe "should have moderation" do
      before do
        @moderation = Moderation.find_by(domain: domain)
      end

      it "moderation should be created" do
        expect(@moderation).not_to be nil
      end

      it "has correct moderator_user_id" do
        expect(@moderation.moderator_user_id).to eq user.id
      end

      it "has correct action" do
        expect(@moderation.action).to eq "Unbanned"
      end

      it "has correct reason" do
        expect(@moderation.reason).to eq "Test reason"
      end
    end
  end
end
