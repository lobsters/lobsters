# typed: false

require "rails_helper"

# uses page.driver.post because we're not running a full js engine,
# so the call can't just be click_on('delete'), etc.

RSpec.feature "Commenting" do
  let(:user) { create(:user) }
  let(:story) { create(:story) }

  before(:each) { stub_login_as user }

  scenario "posting a comment" do
    visit "/s/#{story.short_id}"
    expect(page).to have_button("Post")
    fill_in "comment", with: "An example comment"
    click_on "Post"
    visit "/s/#{story.short_id}"
    expect(page).to have_content("example comment")
  end

  scenario "posting a comment with a hat" do
    hat = create(:hat, user: user)
    visit "/s/#{story.short_id}"
    fill_in "comment", with: "An example comment"
    select hat.hat, from: "hat_id"
    click_on "Post"
    visit "/s/#{story.short_id}"
    expect(page).to have_css("span.hat")
  end

  feature "editing comments" do
    scenario "adding a hat to a comment" do
      hat = create(:hat, user: user)
      comment = create(:comment, story: story, user: user, hat: nil)
      visit "/s/#{story.short_id}"
      expect(page).to_not have_css("span.hat")

      visit "/comments/#{comment.short_id}/edit"
      select hat.hat, from: "hat_id"
      click_on "Update"

      visit "/s/#{story.short_id}"
      expect(page).to have_css("span.hat")
    end
  end

  feature "deleting comments" do
    scenario "deleting a comment" do
      comment = create(:comment,
        user_id: user.id,
        story_id: story.id,
        created_at: 1.day.ago)
      visit "/s/#{story.short_id}"
      expect(page).to have_link("delete")

      page.driver.post "/comments/#{comment.short_id}/delete"
      visit "/s/#{story.short_id}"
      expect(page).to have_link("undelete")
      comment.reload
      expect(comment.is_deleted?).to be(true)
    end

    scenario "trying to delete old comments" do
      comment = create(:comment, user: user, story: story, created_at: 90.days.ago)
      visit "/s/#{story.short_id}"
      expect(page).not_to have_link("delete")

      page.driver.post "/comments/#{comment.short_id}/delete"
      comment.reload
      expect(comment.is_deleted?).to be(false)
    end
  end

  feature "disowning comments" do
    scenario "disowning a comment" do
      # bypass validations to create inactive-user:
      create(:user, :inactive)

      comment = create(:comment, user_id: user.id, story_id: story.id, created_at: 90.days.ago)
      visit "/s/#{story.short_id}"
      expect(page).to have_button("disown")

      page.driver.post "/comments/#{comment.short_id}/disown"
      comment.reload
      expect(comment.user).not_to eq(user)
      visit "/s/#{story.short_id}"
      expect(page).to have_content("inactive-user")
    end

    scenario "trying to disown recent comments" do
      comment = create(:comment, user_id: user.id, story_id: story.id, created_at: 1.day.ago)
      visit "/s/#{story.short_id}"
      expect(page).not_to have_link("disown")

      page.driver.post "/comments/#{comment.short_id}/disown"
      comment.reload
      expect(comment.user).to eq(user)
    end
  end

  feature "Merging story comments" do
    scenario "upvote merged story comments" do
      reader = create(:user)
      hot_take = create(:story)

      comment = create(
        :comment,
        user_id: user.id,
        story_id: story.id,
        created_at: 90.days.ago,
        comment: "Cool story."
      )
      visit "/settings"
      click_on "Logout"

      stub_login_as reader
      visit "/s/#{story.short_id}"
      expect(page.find(:css, ".comment .comment_text")).to have_content("Cool story.")
      expect(comment.score).to eq(1)
      page.driver.post "/comments/#{comment.short_id}/upvote"
      comment.reload
      expect(comment.score).to eq(2)

      story.update!(merged_stories: [hot_take])
      visit "/s/#{story.short_id}"
      expect(page.find(:css, ".comment.upvoted .score")).to have_content("2")
    end
  end
end
