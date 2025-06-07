# typed: false

require "rails_helper"

RSpec.feature "Editing Hats" do
  let!(:hat) { create(:hat, link: "foo@bar.com") }
  let!(:mod) { create(:user, :moderator) }
  let!(:user_with_hat) { create(:user, hats: [hat]) }
  let!(:story) { create(:story, user: user_with_hat) }
  let!(:comment) { create(:comment, story: story, user: user_with_hat, hat: hat) }

  before do
    stub_login_as mod

    visit "/hats"
  end

  scenario "edit button is present on hats page" do
    expect(page).to have_selector(:link_or_button, "Edit")
  end

  scenario "editing hat in place" do
    click_on "Edit"
    visit "/hats/#{hat.short_id}/edit"

    renamed_hat_text = "new hat"
    expect(page).to have_selector(:link_or_button, "Edit In-Place")
    fill_in "hat[hat]", with: renamed_hat_text
    click_on "Edit In-Place"
    expect(page).to have_content(renamed_hat_text)

    expect(story.comments.first.hat.hat).to eq(renamed_hat_text)

    mod_log = Moderation.last
    expect(mod_log.action).to match(/Renamed hat "#{hat.hat}" to "#{renamed_hat_text}"/)
  end

  scenario "doffing and replacing with new hat" do
    click_on "Edit"
    visit "/hats/#{hat.short_id}/edit"

    replaced_hat_text = "new hat"
    expect(page).to have_selector(:link_or_button, "Doff & Create")
    fill_in "hat[hat]", with: replaced_hat_text
    click_on "Doff & Create"
    expect(page).to have_content(replaced_hat_text)

    new_hat = Hat.last
    create(:comment, story: story, user: user_with_hat, hat: new_hat)

    expect(story.comments.first.hat.hat).to eq(hat.hat)
    expect(story.comments.second.hat.hat).to eq(new_hat.hat)

    mod_log = Moderation.last
    expect(mod_log.action).to eq("Doffed hat \"#{hat.hat}\"")
    expect(mod_log.reason).to eq("To replace with \"#{new_hat.hat}\"")
  end
end
