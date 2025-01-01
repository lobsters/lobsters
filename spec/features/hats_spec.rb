# typed: false

require "rails_helper"

RSpec.feature "Viewing Hats page", type: :feature do
  feature "when logged out" do
    scenario "cannot see a user's email" do
      hat = create(:hat, link: "foo@bar.com")
      user_with_hat = create(:user, hats: [hat])

      visit "/hats"

      expect(page).to have_content("bar.com")
      expect(page).to_not have_content(user_with_hat.hats.first.link)
    end
  end

  feature "when logged in" do
    scenario "can see a user's hats" do
      hat = create(:hat, link: "foo@bar.com")
      user_with_hat = create(:user, hats: [hat])
      stub_login_as user_with_hat

      visit "/hats"

      expect(page).to have_content(user_with_hat.hats.first.link)
    end
  end
end
