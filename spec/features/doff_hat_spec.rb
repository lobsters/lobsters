# typed: false

require "rails_helper"

RSpec.feature "Doffing Hats" do
  let(:user) { create(:user) }
  let(:hat) { create(:hat, user: user) }

  before(:each) { stub_login_as user }

  scenario "doffing hat with reason" do
    hat.reload
    visit user_path(user)
    expect(page).to have_selector(:link_or_button, "Doff")

    doffing_reason = "Left project"
    click_on "Doff"
    visit "/hats/#{hat.short_id}/doff"
    fill_in "reason", with: doffing_reason
    click_on "Doff Hat"
    expect(page).to have_content("doffed")

    mod = Moderation.last
    expect(mod.action).to start_with "Doffed hat"
    expect(mod.reason).to eq(doffing_reason)
  end
end
