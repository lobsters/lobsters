# typed: false

require "rails_helper"

RSpec.feature "Origins" do
  let(:admin) { create(:user, :admin) }

  before(:each) { stub_login_as admin }

  context "origins_ban#update" do
    let!(:origin) { create(:origin, identifier: "github.com/alice") }

    it "bans origin with valid params" do
      visit "/mod/origins/github.com%2Falice/edit"
      fill_in "Ban Reason", with: "just because"
      click_on "Ban"
      expect(page).to have_text("Origin updated")
      expect(origin.reload).to be_banned
    end

    it "does not ban origin when the reason is blank" do
      visit "/mod/origins/github.com%2Falice/edit"
      fill_in "Ban Reason", with: ""
      click_on "Ban"
      expect(page).to have_text("Reason required")
      expect(origin.reload).to_not be_banned
    end
  end

  context "unban" do
    let!(:origin) { create(:origin, :banned, identifier: "github.com/alice") }

    it "unbans  origin with valid params" do
      visit "/mod/origins/github.com%2Falice/edit"
      fill_in "Unban Reason", with: "am i not merciful"
      click_on "Unban"
      expect(page).to have_text("Origin updated")
      expect(origin.reload).to_not be_banned
    end
  end

  context "create and ban" do
    it "can create and ban an origin that hasn't been submitted yet" do
      visit "/mod/origins/github.com%2Fslopper/edit"
      fill_in "Create and Ban Reason", with: "Emailed me slop to post."
      click_on "Create and Ban"
      expect(page).to have_text("Origin created and banned")

      origin = Origin.find_by(identifier: "github.com/slopper")
      expect(origin).to be_present
      expect(origin).to be_banned
    end

    it "does not create and ban when the reason is blank" do
      visit "/mod/origins/github.com%2Fslopper/edit"
      fill_in "Create and Ban Reason", with: ""
      click_on "Create and Ban"
      expect(page).to have_text("A reason is required to ban")
      expect(page).to have_button("Create and Ban")
      expect(Origin.find_by(identifier: "github.com/asdfasdf")).to be_nil
    end
  end
end
