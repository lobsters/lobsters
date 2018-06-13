require 'rails_helper'

RSpec.feature "Reading Homepage", type: feature do
  let!(:story) { create(:story) }

  feature "when logged out" do
    scenario "reading a story" do
      visit "/"
      expect(page).to have_content(story.title)
    end
  end

  feature "when logged in" do
    let(:user) { create(:user) }
    before(:each) { stub_login_as user }

    scenario "reading a story" do
      visit "/"
      expect(page).to have_content(story.title)
    end
  end
end
