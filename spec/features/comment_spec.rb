require 'rails_helper'

# uses page.driver.post because we're not running a full js engine,
# so the call can't just be click_on('delete'), etc.

RSpec.feature "Commenting" do
  let(:story) { Story.make! title: "Example Story" }
  let(:user) { User.make! username: 'user' }

  before(:each) { stub_login_as user }

  scenario 'posting a comment' do
    visit "/s/#{story.short_id}"
    expect(page).to have_button('Post')
    fill_in 'comment', with: 'An example comment'
    click_on 'Post'
    visit "/s/#{story.short_id}"
    expect(page).to have_content('example comment')
  end

  feature "deleting comments" do
    scenario 'deleting a comment' do
      comment = Comment.make!(
        comment: 'An example comment',
        user_id: user.id,
        story_id: story.id,
        created_at: 1.day.ago,
      )
      visit "/s/#{story.short_id}"
      expect(page).to have_link('delete')

      page.driver.post "/comments/#{comment.short_id}/delete"
      visit "/s/#{story.short_id}"
      expect(page).to have_link('undelete')
      comment.reload
      expect(comment.is_deleted?)
    end

    scenario 'trying to delete old comments' do
      comment = Comment.make!(
        comment: 'An example comment',
        user_id: user.id,
        story_id: story.id,
        created_at: 90.days.ago,
      )
      visit "/s/#{story.short_id}"
      expect(page).not_to have_link('delete')

      page.driver.post "/comments/#{comment.short_id}/delete"
      comment.reload
      expect(!comment.is_deleted?)
    end
  end

  feature "disowning comments" do
    scenario 'disowning a comment' do
      # bypass validations to create inactive-user:
      User.make!.tap {|u| u.update_column :username, 'inactive-user' }

      comment = Comment.make! user_id: user.id, story_id: story.id, created_at: 90.days.ago
      visit "/s/#{story.short_id}"
      expect(page).to have_link('disown')

      page.driver.post "/comments/#{comment.short_id}/disown"
      comment.reload
      expect(comment.user).not_to eq(user)
      visit "/s/#{story.short_id}"
      expect(page).to have_content('inactive-user')
    end

    scenario 'trying to disown recent comments' do
      comment = Comment.make! user_id: user.id, story_id: story.id, created_at: 1.day.ago
      visit "/s/#{story.short_id}"
      expect(page).not_to have_link('disown')

      page.driver.post "/comments/#{comment.short_id}/disown"
      puts page.body
      comment.reload
      expect(comment.user).to eq(user)
    end
  end
end
