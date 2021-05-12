require 'rails_helper'

RSpec.feature "Reading Stories", type: :feature do
  let!(:story) { create(:story) }
  let!(:comment) { create(:comment, story: story) }

  feature "when logged out" do
    # scenario "reading a story" do
    #   visit "/s/#{story.short_id}"
    #   expect(page).to have_content(story.title)
    #   expect(page).to have_content(comment.comment)
    # end
  end

  feature "when logged in" do
    let(:user) { create(:user) }

    before(:each) { stub_login_as user }

    # scenario "reading a story" do
    #   visit "/s/#{story.short_id}"
    #   expect(page).to have_content(story.title)
    #   expect(page).to have_content(comment.comment)

    #   fill_in "comment", with: "New reply"
    #   click_button "Post"

    #   expect(page).to have_content("New reply")
    # end
  end

  feature "reading merged stories" do
    let!(:merged) { create(:story, merged_into_story: story) }

    # it "redirects links" do
    #   visit merged.comments_path
    #   expect(page).to have_current_path(story.comments_path)
    # end

    # it "shows merged story at the top" do
    #   visit story.comments_path
    #   expect(page).to have_content(merged.title)
    # end

    # it "shows comments from merged_into story" do
    #   visit story.comments_path
    #   expect(page).to have_content(comment.comment)
    # end

    # it "shows comments from merged story" do
    #   merged_comment = create(:comment, story: merged)
    #   merged_reply = create(:comment, story: merged, parent_comment: merged_comment)
    #   visit story.comments_path

    #   expect(page).to have_content(merged_comment.comment)
    #   expect(page).to have_content(merged_reply.comment)
    #   expect(page).to have_selector('span.merge')
    # end
  end
end
