# typed: false

require "rails_helper"

RSpec.feature "Hiding Stories", type: :feature do
  feature "when logged out" do
    let!(:story) { create(:story) }

    scenario "visiting homepage" do
      visit "/"

      expect(page).not_to have_css(".hider")
    end

    scenario "reading a story" do
      visit "/s/#{story.short_id}"

      expect(page).not_to have_css(".hider")
    end
  end

  feature "when logged in" do
    let(:user) { create(:user) }
    let!(:story) { create(:story) }

    before(:each) { stub_login_as user }

    after(:each) { HiddenStory.unhide_story_for_user(story, user) }

    scenario "reading homepage" do
      visit "/"

      expect(page).to have_css(".hider")
      expect(page).to have_button("hide")
    end

    scenario "reading a story" do
      visit "/s/#{story.short_id}"

      expect(page).to have_css(".hider")
      expect(page).to have_button("hide")
    end

    scenario "hiding a story" do
      HiddenStory.hide_story_for_user(story, user)

      visit "/s/#{story.short_id}"

      expect(page).not_to have_button("hide", exact: true)
      expect(page).to have_button("unhide", exact: true)
      expect(page).to have_content("You have hidden this story")
    end

    scenario "unhiding a story" do
      HiddenStory.unhide_story_for_user(story, user)

      visit "/s/#{story.short_id}"

      expect(page).to have_button("hide", exact: true)
      expect(page).not_to have_button("unhide", exact: true)
      expect(page).not_to have_content("You have hidden this story")
    end

    scenario "visiting story hidden by other user" do
      another_user = create(:user)
      another_story = create(:story)

      HiddenStory.hide_story_for_user(another_story, another_user)

      visit "/s/#{another_story.short_id}"
      expect(page).to have_button("hide", exact: true)
      expect(page).to have_content("hidden by 1 user")
    end

    scenario "visiting story hidden by current user and another user" do
      another_user = create(:user)
      another_story = create(:story)

      HiddenStory.hide_story_for_user(another_story, another_user)
      HiddenStory.hide_story_for_user(another_story, user)

      visit "/s/#{another_story.short_id}"
      expect(page).to have_button("unhide", exact: true)
      expect(page).to have_content("hidden by you and 1 other user")
    end

    scenario "visiting a merged story individual hidden stories" do
      user_alice = create(:user)
      user_bob = create(:user)

      another_story = create(:story)

      HiddenStory.hide_story_for_user(another_story, user_alice)
      HiddenStory.hide_story_for_user(another_story, user)

      merged = create(:story, merged_into_story: another_story)

      HiddenStory.hide_story_for_user(merged, user_alice)
      HiddenStory.hide_story_for_user(merged, user_bob)

      visit "/s/#{another_story.short_id}"
      expect(page).to have_content("hidden by 2 users")
      expect(page).to have_content("hidden by you and 1 other user")
    end
  end
end
