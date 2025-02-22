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

    it "displays 'Last Read' marker at the last loaded position and update 'last_read_newest' accordingly" do
      user = create(:user, last_read_newest: 2.hours.ago)

      stub_login_as user

      stub_const "StoriesPaginator::STORIES_PER_PAGE", 3

      create(:story, title: "story 1", created_at: 3.hours.ago)
      create(:story, title: "story 2", created_at: 3.hours.ago)
      create(:story, title: "story 3", created_at: 1.hours.ago)
      create(:story, title: "story 4", created_at: 1.hours.ago)
      create(:story, title: "story 5", created_at: 1.hours.ago)
      create(:story, title: "story 6", created_at: 1.hours.ago)

      visit "/newest"
      expect(page.body).not_to include("Last Read")
      expect(user.reload.last_read_newest).not_to be_within(1.second).of Time.zone.now

      visit "/newest/page/2"
      expect(page.body).to include("Last Read")
      page_html = page.body
      last_read_index = page_html.index("Last Read")
      story_2_index = page_html.index("story 2")

      expect(last_read_index).to be < story_2_index, "'Last Read' should appear before 'story 2'"
      expect(user.reload.last_read_newest).to be_within(1.second).of Time.zone.now
    end
  end
end
