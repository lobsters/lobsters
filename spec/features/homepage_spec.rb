require 'rails_helper'

RSpec.feature "Reading Homepage", type: :feature do
  let!(:story) { create(:story) }

  feature "when logged out" do
    scenario "reading a story" do
      visit "/"
      expect(page).to have_content(story.title)
    end
  end

  feature "when logged in" do
    let(:user) { create(:user) }

    before(:each) { stub_login_as user }

    scenario "reading a story" do
      visit "/"
      expect(page).to have_content(story.title)
    end
  end

  feature "browsing stories by tag" do
    let(:tag_a) { Tag.create(tag: 'A1').tag }
    let(:tag_b) { Tag.create(tag: 'B2').tag }
    let!(:ab_story) { create(:story, tags_a: [tag_a, tag_b]) }
    let!(:a_story) { create(:story, tags_a: [tag_a]) }
    let!(:b_story) { create(:story, tags_a: [tag_b]) }

    scenario "viewing one tag at a time" do
      visit "/t/#{tag_a}"

      expect(page).to have_content(ab_story.title)
      expect(page).to have_content(a_story.title)

      visit "/t/#{tag_b}"

      expect(page).to have_content(ab_story.title)
      expect(page).to have_content(b_story.title)
    end

    scenario "viewing two tags" do
      tags = [tag_a, tag_b].join(",")
      visit "/t/#{tags}"

      expect(page).to have_content(ab_story.title)
      expect(page).to have_content(a_story.title)
      expect(page).to have_content(b_story.title)
    end

    context "errors" do
      scenario "non-existent tag raises error" do
        expect { visit "/t/definitelynosuchtaghere" }.to raise_error
      end

      scenario "non-existent tag with existing tag raises an error" do
        expect { visit "/t/#{tag_a},definitelynosuchtaghere" }.to raise_error
      end

      scenario "non-unique existing tags raises an error" do
        expect { visit "/t/#{tag_a},#{tag_a}" }.to raise_error
      end
    end
  end
end
