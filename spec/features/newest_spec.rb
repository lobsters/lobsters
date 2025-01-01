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

    it "updates the user's last-read line" do
      user = create(:user, last_read_newest: 3.days.ago)
      stub_login_as user
      visit "/newest"
      expect(user.reload.last_read_newest).to be_within(1.second).of Time.zone.now
    end
  end
end
