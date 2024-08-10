# typed: false

require "rails_helper"

# uses page.driver.post because we're not running a full js engine,
# so the call can't just be click_on('delete'), etc.

RSpec.feature "user threads page ~:user/threads" do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }

  scenario "viewing user's threads" do
    poster = create(:user)
    parent = create(:comment, story: story, user: poster)
    reply = create(:comment, story: story, user: user, parent_comment: parent)

    visit "/threads/#{user.username}"
    expect(page).to have_content(parent.comment)
    expect(page).to have_content(reply.comment)
  end

  scenario "comments on a deleted story" do
    comment = create(:comment, user: user, story: story, comment: "Comment text visible")

    visit "/threads/#{user.username}"
    expect(page).to have_content(comment.comment)

    story.editor = create(:user, :moderator)
    story.is_deleted = true
    story.save!

    # check that story was really deleted because the above code is brittle
    visit story.short_id_url
    expect(page).to have_content("was removed")

    visit "/threads/#{user.username}"
    expect(page).to_not have_content(comment.comment)
  end
end
