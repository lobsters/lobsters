# typed: false

require "rails_helper"

RSpec.feature "Domains" do
  let(:admin) { create(:user, :admin) }

  before(:each) { stub_login_as admin }

  context "create" do
    it "creates domains with selectors" do
      visit "/domains/nogweii.net/edit"
      fill_in "selector", with: "\\Ahttps?://nogweii.net/+([^/]+).*\\z"
      fill_in "replacement", with: "nogweii.net/\\1"
      click_on "Save"
      expect(page).to have_text("Domain created")
      expect(Domain.last.domain).to eq("nogweii.net")
    end

    it "updates domains with selectors" do
      domain = create(:domain)
      visit "/domains/#{domain.domain}/edit"
      fill_in "selector", with: "\\Ahttps?://nogweii.net/+([^/]+).*\\z"
      fill_in "replacement", with: "nogweii.net/\\1"
      click_on "Save"
      expect(page).to have_text("Domain edited")
    end
  end

  context "domains_ban#update" do
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

  context "create and ban" do
    let(:domain_name) { Faker::Internet.domain_name }

    it "can create and ban at the same time" do
      visit "/domains/#{domain_name}/edit"
      fill_in "Create and Ban Reason", with: "Hasn't finished a Gameboy emulator"
      click_on "Create and Ban"
      expect(page).to have_text("Domain created and banned")
      expect(Domain.last).to be_banned
    end
  end
end
