# frozen_string_literal: true

require 'rails_helper'

RSpec.feature "Submitting Stories", type: :feature do
  let(:user) { create(:user) }
  before(:each) { stub_login_as user }

  scenario "submitting a link" do
    visit "/stories/new"
    fill_in "URL", with: "https://example.com/page"
    fill_in "Title", with: "Example Story"
    select :tag1, from: 'Tags'
    click_button "Submit"

    expect(page).not_to have_content "prohibited this story from being saved"
  end
end
