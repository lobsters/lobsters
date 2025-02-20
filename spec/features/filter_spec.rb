# typed: false

require "rails_helper"

RSpec.feature "Filtering" do
  let!(:tag) { create(:tag) }

  scenario "Loading filter page" do
    visit "/filters"
    expect(page).to have_content("Filtered Tags")
  end

  context "with a story with the tag" do
    let!(:story) { create(:story, tags: Tag.where(tag: [tag.tag])) }

    context "as a logged-out visitor" do
      scenario "adding a filter" do
        visit "/filters"
        expect(page.driver.request.cookies["tag_filters"]).to be_nil

        check tag.description
        click_on "Save Filters"

        expect(page).to have_checked_field(tag.description)
        expect(page.driver.request.cookies["tag_filters"]).to eq(tag.to_param)

        visit "/"
        expect(page).to_not have_content(story.title)
      end
    end

    context "as a logged-in user" do
      let(:user) { create(:user) }

      before(:each) { stub_login_as user }

      scenario "adding a filter" do
        visit "/filters"
        expect(user.tag_filters).to be_empty

        check tag.description
        click_on "Save Filters"

        expect(page).to have_checked_field(tag.description)
        expect(user.tag_filters.map(&:tag)).to eq([tag])

        visit "/"
        expect(page).to_not have_content(story.title)
      end
    end
  end

  context "privileged tag" do
    let!(:tag) { create(:tag, privileged: true) }

    scenario "no filter checkbox is shown" do
      visit "/filters"

      expect(page).to have_content(tag.description)
      expect(page).to_not have_field(tag.description)
    end

    context "when the user is a moderator" do
      let(:user) { create(:user, :moderator) }

      before(:each) { stub_login_as user }

      scenario "the user can filter the privileged tag" do
        visit "/filters"
        expect(user.tag_filters).to be_empty

        check tag.description
        click_on "Save Filters"

        expect(page).to have_checked_field(tag.description)
        expect(user.tag_filters.map(&:tag)).to eq([tag])
      end
    end
  end

  context "inactive tag" do
    let!(:tag) { create(:tag, active: false) }

    scenario "tag isn't shown" do
      visit "/filters"

      expect(page).to_not have_content(tag.description)
    end
  end
end
