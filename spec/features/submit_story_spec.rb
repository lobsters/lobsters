require 'rails_helper'

RSpec.feature "Submitting Stories", type: :feature do
  let(:user) { create(:user) }
  before(:each) { stub_login_as user }

  scenario "submitting a link" do
    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://example.com/page"
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      expect(page).not_to have_content "prohibited this story from being saved"
    }.to(change { Story.count })
  end

  scenario "resubmitting a recent link" do
    s = create(:story, created_at: 1.day.ago)
    expect {
      visit "/stories/new"
      fill_in "URL", with: s.url
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      expect(page).to have_content "Error: This story was submitted"
    }.not_to(change { Story.count })
  end

  scenario "resubmitting a recent link deleted by a moderator" do
    s = create(:story, is_expired: true, is_moderated: true, created_at: 1.day.ago)
    expect {
      visit "/stories/new"
      fill_in "URL", with: s.url
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      expect(page).to have_content "Error: This story was submitted"
    }.not_to(change { Story.count })
  end

  scenario "resubmitting an old link" do
    s = create(:story, created_at: (Story::RECENT_DAYS + 1).days.ago)
    visit "/stories/new?url=#{s.url}"

    expect(page).to have_content "may be submitted again"
    expect(page).to have_content "Previous discussions"
  end
end
