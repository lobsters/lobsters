require 'rails_helper'

RSpec.feature "Viewing User page", type: :feature do

  feature "when logged out" do
    scenario "cannot see a user's hats" do
      hat = create(:hat, hat: "Best Hat")
      user_with_hat = create(:user, hats: [hat])

      visit "/u/#{user_with_hat.username}"

      expect(page).to_not have_content(user_with_hat.hats.first.hat)
    end
  end

  feature "when logged in" do
    scenario "can see a user's hats" do
      hat = create(:hat, hat: "Best Hat")
      user_with_hat = create(:user, hats: [hat])
      stub_login_as user_with_hat

      visit "/u/#{user_with_hat.username}"

      expect(page).to have_content(user_with_hat.hats.first.hat)
    end
  end

end
