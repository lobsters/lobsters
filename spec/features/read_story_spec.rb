# typed: false

require "rails_helper"

RSpec.feature "Reading Stories", type: :feature do
  feature "when logged out" do
    let!(:story) { create(:story) }
    let!(:comment) { create(:comment, story:) }

    scenario "reading a story" do
      visit "/s/#{story.short_id}"
      expect(page).to have_content(story.title)
      expect(page).to have_content(comment.comment)
    end
  end

  feature "when logged in" do
    let(:user) { create(:user) }
    let!(:story) { create(:story) }
    let!(:comment) { create(:comment, story:) }

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

  feature "reading merged stories" do
    let!(:story) { create(:story) }
    let!(:comment) { create(:comment, story:) }
    let!(:merged) { create(:story, merged_into_story: story) }

    it "redirects links" do
      visit merged.comments_path
      expect(page).to have_current_path(story.comments_path)
    end

    it "shows merged story at the top" do
      visit story.comments_path
      expect(page).to have_content(merged.title)
    end

    it "shows comments from merged_into story" do
      visit story.comments_path
      expect(page).to have_content(comment.comment)
    end

    it "shows comments from merged story" do
      merged_comment = create(:comment, story: merged)
      merged_reply = create(:comment, story: merged, parent_comment: merged_comment)
      visit story.comments_path

      expect(page).to have_content(merged_comment.comment)
      expect(page).to have_content(merged_reply.comment)
      expect(page).to have_selector("span.merge")
    end
  end

  feature "reading saved stories" do
    let(:user) { create(:user) }
    let!(:user_edited_story) { create(:story, editor: user) }

    before do
      stub_login_as user
      SavedStory.save_story_for_user(user_edited_story.id, user.id)
    end

    scenario "when story is deleted" do
      visit "/saved"

      expect(page).not_to have_css("a.saver", text: "save", exact_text: true)
      expect(page).to have_link("unsave")
    end

    scenario "when story is available" do
      visit "/saved"

      expect(page).not_to have_css("a.saver", text: "save", exact_text: true)
      expect(page).to have_link("unsave")
    end
  end

  feature "reading deleted stories" do
    let(:user) { create(:user) }
    let!(:deleted_story) { create(:story, is_deleted: true) }

    before do
      stub_login_as user
      visit "/"
    end

    it "does not display saver links" do
      expect(page).not_to have_css("a.saver", text: "save", exact_text: true)
      expect(page).not_to have_link("unsave")
    end
  end
end
