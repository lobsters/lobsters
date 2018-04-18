require 'rails_helper'

RSpec.feature "Reading Stories", type: :feature do
  let!(:story) { Story.make! title: "Example Story" }
  let!(:comment) { Comment.make! story_id: story.id, comment: "Example comment" }

  feature "when logged out" do
    scenario "reading a story" do
      visit "/s/#{story.short_id}"
      expect(page).to have_content(story.title)
      expect(page).to have_content(comment.comment)
    end
  end

  feature "when logged in" do
    let(:user) { User.make! }
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
