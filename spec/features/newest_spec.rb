# typed: false

require "rails_helper"

RSpec.feature "Reading Homepage", type: :feature do
  feature "/newest" do
    it "shows stories, most-recent first" do
      # this creates the old record first because some code uses Story.id (an autoincrementing int)
      # as a proxy for creation order to sort by date
      create(:story, title: "older story", created_at: 2.hours.ago)
      create(:story, title: "newer story", created_at: 1.hour.ago)
      visit "/newest"
      body = page.body
      expect(body.index("older_story")).to be > body.index("newer story")
    end

    it "displays 'Last Read' marker at the last loaded position and maintains last_read_timestamp through pagination accordingly" do
      user = create(:user, last_read_newest_story: 2.hours.ago)

      stub_login_as user

      stub_const "StoriesPaginator::STORIES_PER_PAGE", 3

      create(:story, title: "story 1", created_at: 3.hours.ago)
      create(:story, title: "story 2", created_at: 3.hours.ago)
      create(:story, title: "story 3", created_at: 1.hour.ago)
      create(:story, title: "story 4", created_at: 1.hour.ago)
      create(:story, title: "story 5", created_at: 1.hour.ago)
      create(:story, title: "story 6", created_at: 1.hour.ago)

      visit "/newest"
      expect(page.body).not_to include("Last Read")
      expect(user.reload.last_read_newest_story).to be_within(1.second).of Time.zone.now

      expect(page).to have_link("Page 2", href: /last_read_timestamp=\d+/)
      click_link "Page 2"
      expect(page.body).to include("Last Read")
      page_html = page.body
      last_read_index = page_html.index("Last Read")
      story_2_index = page_html.index("story 2")
      expect(last_read_index).to be < story_2_index, "'Last Read' should appear before 'story 2'"
      expect(user.reload.last_read_newest_story).to be_within(1.second).of Time.zone.now
      expect(page).not_to have_link(href: /last_read_timestamp=\d+/)
    end
  end

  feature "/comments" do
    it "shows comments, most-recent first" do
      create(:comment, comment: "old comment", created_at: 2.hours.ago)
      create(:comment, comment: "new comment", created_at: 1.hour.ago)
      visit "/comments"
      body = page.body
      expect(body.index("old comment")).to be > body.index("new comment")
    end

    it "displays 'Last Read' marker at the last loaded position and update 'last_read_newest_comment' accordingly" do
      user = create(:user, last_read_newest_comment: 2.hours.ago)

      stub_login_as user

      stub_const "CommentsController::COMMENTS_PER_PAGE", 3

      create(:comment, comment: "comment 1", created_at: 3.hours.ago)
      create(:comment, comment: "comment 2", created_at: 3.hours.ago)
      create(:comment, comment: "comment 3", created_at: 1.hours.ago)
      create(:comment, comment: "comment 4", created_at: 1.hours.ago)
      create(:comment, comment: "comment 5", created_at: 1.hours.ago)
      create(:comment, comment: "comment 6", created_at: 1.hours.ago)

      visit "/comments"
      expect(page.body).not_to include("Last Read")
      expect(user.reload.last_read_newest_comment).to be_within(1.second).of Time.zone.now

      expect(page).to have_link("Page 2", href: /last_read_timestamp=\d+/)
      click_link "Page 2"
      expect(page.body).to include("Last Read")
      page_html = page.body
      last_read_index = page_html.index("Last Read")
      comment_2_index = page_html.index("comment 2")
      expect(last_read_index).to be < comment_2_index, "'Last Read' should appear before 'comment 2'"
      expect(user.reload.last_read_newest_comment).to be_within(1.second).of Time.zone.now
      expect(page).not_to have_link(href: /last_read_timestamp=\d+/)
    end

    it "filters out comments by tag" do
      create(:comment, comment: "shown", created_at: 2.hours.ago)
      filtered_tag = create(:tag)
      tagged_story = create(:story, tags: [filtered_tag])
      create(:comment, story: tagged_story, comment: "filteredout", created_at: 1.hour.ago)

      user = create(:user)
      user.tag_filters.create!(tag: filtered_tag)
      stub_login_as user

      visit "/comments"
      expect(page.body).to include("shown")
      expect(page.body).to_not include("filteredout")
    end
  end
end
