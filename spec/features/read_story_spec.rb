require 'rails_helper'

RSpec.feature "Reading Stories", type: :feature do
  let!(:story) { create(:story) }
  let!(:comment) { create(:comment, story: story) }

  feature "when logged out" do
    scenario "reading a story" do
      visit "/s/#{story.short_id}"
      expect(page).to have_content(story.title)
      expect(page).to have_content(comment.comment)
    end
  end

  feature "when logged in" do
    let(:user) { create(:user) }
    before(:each) { stub_login_as user }

    scenario "reading a story" do
      visit "/s/#{story.short_id}"
      expect(page).to have_content(story.title)
      expect(page).to have_content(comment.comment)

      fill_in "comment", with: "New reply"
      click_button "Post"

      expect(page).to have_content("New reply")
    end
  end
end
