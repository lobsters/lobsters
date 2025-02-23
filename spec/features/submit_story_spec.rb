# typed: false

require "rails_helper"

RSpec.feature "Submitting Stories", type: :feature do
  let(:user) { create(:user) }
  let!(:inactive_user) { create(:user, :inactive) }

  before(:each) { stub_login_as user }

  scenario "submitting a link" do
    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://example.com/page"
      fill_in "Title", with: "Example Story"
      select :tag1, from: "Tags"
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
          select :tag1, from: "Tags"
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
          select :tag1, from: "Tags"
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
      select :tag1, from: "Tags"
      click_button "Submit"

      expect(page).to have_content "has already been submitted"
    }.not_to(change { Story.count })
  end

  scenario "new user submitting an unseen domain" do
    inactive_user # TODO: remove reference after satisfying rubocop RSpec/LetSetup properly
    user.update!(created_at: 1.day.ago)
    refute(Domain.where(domain: "example.net").exists?)
    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://example.net/story"
      fill_in "Title", with: "Example Story"
      select :tag1, from: "Tags"
      click_button "Submit"

      expect(page).to have_content "unseen domain"
    }.not_to(change { Story.count })
  end

  scenario "new user submitting a new origin from a multi-author domain" do
    pending "Story submission approval - this would probably have a high false-positive rate"

    inactive_user # TODO: remove reference after satisfying rubocop RSpec/LetSetup properly
    create(:domain, :github_with_selector)
    create(:story, url: "https://github.com/alice")
    user.update!(created_at: 1.day.ago)
    refute(Origin.where(identifier: "github.com/bob").exists?)
    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://github.com/bob/cryptocurrency"
      fill_in "Title", with: "Example Story"
      select :tag1, from: "Tags"
      click_button "Submit"
      expect(page).to have_content "multiple authors"
    }.not_to(change { Story.count })
  end

  scenario "new user resubmitting a link" do
    user.update!(created_at: 1.day.ago)
    s = create(:story, created_at: 1.year.ago)
    expect {
      visit "/stories/new"
      fill_in "URL", with: s.url
      fill_in "Title", with: "Example Story"
      select :tag1, from: "Tags"
      click_button "Submit"

      expect(page).to have_content "resubmitted by new users"
    }.not_to(change { Story.count })
  end

  scenario "new user submitting with a tag not permitted for new users" do
    inactive_user # TODO: remove reference after satisfying rubocop RSpec/LetSetup properly
    drama = create(:tag, tag: "drama", permit_by_new_users: false)
    earlier_story = create(:story)
    user.update!(created_at: 1.day.ago)
    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://#{earlier_story.domain.domain}/story"
      fill_in "Title", with: "Example Story"
      select drama.tag, from: "Tags"
      click_button "Submit"

      expect(page).to have_content "meta discussion or prone to"
    }.not_to(change { Story.count })
    expect(ModNote.last.user).to eq(user)
  end

  scenario "resubmitting a recent link deleted by a moderator" do
    s = create(:story, is_deleted: true, is_moderated: true, created_at: 1.day.ago)
    expect {
      visit "/stories/new"
      fill_in "URL", with: s.url
      fill_in "Title", with: "Example Story"
      select :tag1, from: "Tags"
      click_button "Submit"

      # TODO: would be nice if this had a specific error message #941
      expect(page).to have_content "has already been submitted"
    }.not_to(change { Story.count })
  end

  context "resubmitting an old link" do
    scenario "prompts user to start a conversation" do
      s = create(:story, created_at: (Story::RECENT_DAYS + 1).days.ago)
      visit "/stories/new?url=#{s.url}"

      expect(page).to have_content "submitted before"
      expect(page).to have_field :comment
    end

    scenario "without a comment doesn't work" do
      s = create(:story, created_at: (Story::RECENT_DAYS + 1).days.ago)
      visit "/stories/new?url=#{s.url}"
      click_button "Submit"

      expect(page).to have_content "submitted before"
      expect(page).to have_content "is missing"
    end

    scenario "with a conversation starter works" do
      s = create(:story, created_at: (Story::RECENT_DAYS + 1).days.ago)
      visit "/stories/new?url=#{s.url}"
      fill_in "comment", with: <<~COMMENT
        Well, everyone knows Custer died at Little Bighorn.
        What this book presupposes is... maybe he didn't.
      COMMENT
      click_button "Submit"

      expect(page).to have_content s.title
      expect(page).to have_content "maybe he didn't"
    end
  end

  scenario "submitting a banned domain" do
    Domain.create!(domain: "example.com", banned_at: DateTime.now)

    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://example.com/tracking?redir=real"
      fill_in "Title", with: "Example Story"
      select :tag1, from: "Tags"
      click_button "Submit"

      expect(page).to have_content "banned"
    }.not_to(change { Story.count })
  end

  scenario "attributing lobsters traffic" do
    inactive_user # TODO: remove reference after satisfying rubocop RSpec/LetSetup properly

    visit "/stories/new"
    fill_in "URL", with: "https://example.com/?lobsters"
    fill_in "Title", with: "Totally Not Marketing"
    select :tag1, from: "Tags"
    click_button "Submit"

    # submitted but attribution stripped
    expect(Story.last.url).to_not include("lobsters")
    expect(ModNote.last.user).to eq(user)
  end

  scenario "brigading" do
    inactive_user # TODO: remove reference after satisfying rubocop RSpec/LetSetup properly

    expect {
      visit "/stories/new"
      fill_in "URL", with: "https://github.com/xkcd/comic/issues/1172"
      fill_in "Title", with: "Yell at this maintainer about my bug"
      select :tag1, from: "Tags"
      click_button "Submit"
    }.not_to(change { Story.count })
    expect(ModNote.last.user).to eq(user)
  end
end
