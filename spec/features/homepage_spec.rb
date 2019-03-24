require 'rails_helper'

RSpec.feature "Reading Homepage", type: feature do
  let!(:story) { create(:story, title: "10 tips for lobstering") }

  feature "when logged out" do
    scenario "reading a story" do
      visit "/"
      expect(page).to have_content("10 tips for lobstering")
    end
  end

  feature "when logged in" do
    let(:user) { create(:user) }
    before(:each) { stub_login_as user }

    scenario "reading a story" do
      visit "/"
      expect(page).to have_content("10 tips for lobstering")
    end
  end
end
