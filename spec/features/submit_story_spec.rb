require 'rails_helper'

RSpec.feature "Submitting Stories", type: :feature do
  let(:user) { create(:user) }
  let!(:inactive_user) { create(:user, :inactive) }

  before(:each) { stub_login_as user }

  scenario "submitting a link" do
    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://example.com/page"
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      expect(page).not_to have_content "prohibited this story from being saved"
    }.to(change { Story.count })
  end

  context "submitting an inline image" do
    context "as a user who is not a moderator" do
      scenario "results in a link, not an image" do
        expect {
          visit "/stories/new"
          fill_in "Text", with: "![](https://lbst.rs/fake.jpg)"
          fill_in "Title", with: "Image Test"
          select :tag1, from: 'Tags'
          click_button "Submit"

          expect(page).to have_css 'a[href="https://lbst.rs/fake.jpg"]'
          expect(page).not_to have_css 'img[src="https://lbst.rs/fake.jpg"]'
        }.to(change { Story.count })
      end
    end

    context "as a user who is a moderator" do
      before { user.update(is_moderator: true) }

      scenario "results in an image, not a link" do
        expect {
          visit "/stories/new"
          fill_in "Text", with: "![](https://lbst.rs/fake.jpg)"
          fill_in "Title", with: "Image Test"
          select :tag1, from: 'Tags'
          click_button "Submit"

          expect(page).not_to have_css 'a[href="https://lbst.rs/fake.jpg"]'
          expect(page).to have_css 'img[src="https://lbst.rs/fake.jpg"]'
        }.to(change { Story.count })
      end
    end
  end

  scenario "resubmitting a recent link" do
    s = create(:story, created_at: 1.day.ago)
    expect {
      visit "/stories/new"
      fill_in "URL", with: s.url
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      expect(page).to have_content "has already been submitted"
    }.not_to(change { Story.count })
  end

  scenario "new user submitting a never-before-seen domain" do
    inactive_user # TODO: remove reference after satisfying rubocop RSpec/LetSetup properly
    user.update(created_at: 1.day.ago)
    refute(Domain.where(domain: 'example.net').exists?)
    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://example.net/story"
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      expect(page).to have_content "unseen domain"
    }.not_to(change { Story.count })
  end

  scenario "new user resubmitting a link" do
    user.update(created_at: 1.day.ago)
    s = create(:story, created_at: 1.year.ago)
    expect {
      visit "/stories/new"
      fill_in "URL", with: s.url
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      expect(page).to have_content "resubmitted by new users"
    }.not_to(change { Story.count })
  end

  scenario "resubmitting a recent link deleted by a moderator" do
    s = create(:story, is_expired: true, is_moderated: true, created_at: 1.day.ago)
    expect {
      visit "/stories/new"
      fill_in "URL", with: s.url
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      # TODO: would be nice if this had a specific error message
      expect(page).to have_content "has already been submitted"
    }.not_to(change { Story.count })
  end

  scenario "resubmitting an old link" do
    s = create(:story, created_at: (Story::RECENT_DAYS + 1).days.ago)
    visit "/stories/new?url=#{s.url}"

    expect(page).to have_content "may be submitted again"
    expect(page).to have_content "Previous discussions"
  end

  scenario "submitting a tracking link" do
    Domain.create!(domain: 'example.com', is_tracker: true)

    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://example.com/tracking?redir=real"
      fill_in "Title", with: "Example Story"
      select :tag1, from: 'Tags'
      click_button "Submit"

      expect(page).to have_content "tracking"
    }.not_to(change { Story.count })
  end
end
