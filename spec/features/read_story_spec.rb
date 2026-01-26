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
      visit Routes.title_path merged
      expect(page).to have_current_path(Routes.title_path(story))
    end

    it "shows merged story at the top" do
      visit Routes.title_path story
      expect(page).to have_content(merged.title)
    end

    it "shows comments from merged_into story" do
      visit Routes.title_path story
      expect(page).to have_content(comment.comment)
    end

    it "shows comments from merged story" do
      merged_comment = create(:comment, story: merged)
      merged_reply = create(:comment, story: merged, parent_comment: merged_comment)
      visit Routes.title_path story

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

      expect(page).not_to have_css("form.saver input.btn-link", text: "save", exact_text: true)
      expect(page).to have_button("unsave")
    end

    scenario "when story is available" do
      visit "/saved"

      expect(page).not_to have_css("form.saver input.btn-link", text: "save", exact_text: true)
      expect(page).to have_button("unsave")
    end
  end

  feature "reading mod-deleted stories" do
    let(:submitter) { create(:user) }
    let(:deleted_story) { create(:story, user: submitter, is_deleted: true, is_moderated: true, title: "Gone Girl") }
    let!(:deletion) { Moderation.create! story: deleted_story, reason: "Ben Affleck has his revenge", action: "Deleted story" }
    let(:other_user) { create(:user) }
    let(:moderator) { create(:user, :moderator) }

    it "is visible to submitter" do
      stub_login_as submitter
      visit "/s/#{deleted_story.short_id}"
      expect(page).to have_text("Gone Girl")
      expect(page).to have_text("Ben Affleck")
    end

    it "is visible to a moderator" do
      stub_login_as moderator
      visit "/s/#{deleted_story.short_id}"
      expect(page).to have_text("Gone Girl")
      expect(page).to have_text("Ben Affleck")
    end

    it "shows moderation but not title/link to other users" do
      stub_login_as other_user
      visit "/s/#{deleted_story.short_id}"
      expect(page).to_not have_text("Gone Girl")
      expect(page).to have_text("Ben Affleck")
    end

    it "shows 'removed' to visitors" do
      visit "/s/#{deleted_story.short_id}"
      expect(page).to_not have_text("Gone Girl")
      expect(page).to_not have_text("Ben Affleck")
    end

    it "does not display saver links" do
      stub_login_as submitter
      visit "/s/#{deleted_story.short_id}"
      expect(page).not_to have_css("a.saver", text: "save", exact_text: true)
      expect(page).not_to have_link("unsave")
    end
  end
end
