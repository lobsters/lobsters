require "rails_helper"

RSpec.feature "Domains" do
  let(:admin) { create(:user, :admin) }

  before(:each) { stub_login_as admin }

  context "update" do
    let(:domain) { create(:domain) }

    it "bans domain with valid params" do
      visit "/domains/#{domain.domain}/edit"
      fill_in "Reason", with: "just because"
      click_on "Ban"
      expect(page).to have_text("Domain updated")
      expect(domain.reload).to be_banned
    end

    it "does not ban domain when the reason is blank" do
      visit "/domains/#{domain.domain}/edit"
      fill_in "Reason", with: ""
      click_on "Ban"
      expect(page).to have_text("Reason required")
      expect(domain.reload).to_not be_banned
    end
  end

  context "unban" do
    let(:domain) { create(:domain, :banned) }

    it "unbans domain with valid params" do
      visit "/domains/#{domain.domain}/edit"
      fill_in "Reason", with: "am i not merciful"
      click_on "Unban"
      expect(page).to have_text("Domain updated")
      expect(domain.reload).to_not be_banned
    end

    it "unbans domain when the reason is blank" do
      visit "/domains/#{domain.domain}/edit"
      fill_in "Reason", with: ""
      click_on "Unban"
      expect(page).to have_text("Reason required")
      expect(domain.reload).to be_banned
    end
  end
end
