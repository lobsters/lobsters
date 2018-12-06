require 'rails_helper'

# uses page.driver.post because we're not running a full js engine,
# so the call can't just be click_on('delete'), etc.

RSpec.feature "Commenting" do
  let(:user) { create(:user) }
  let(:user1) { create(:user) }
  let(:story) { create(:story, user: user) }
  let(:story1) { create(:story, user: user1) }

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
      comment = create(:comment,
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
      comment = create(:comment, user: user, story: story, created_at: 90.days.ago)
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
      create(:user, :inactive)

      comment = create(:comment, user_id: user.id, story_id: story.id, created_at: 90.days.ago)
      visit "/s/#{story.short_id}"
      expect(page).to have_link('disown')

      page.driver.post "/comments/#{comment.short_id}/disown"
      comment.reload
      expect(comment.user).not_to eq(user)
      visit "/s/#{story.short_id}"
      expect(page).to have_content('inactive-user')
    end

    scenario 'trying to disown recent comments' do
      comment = create(:comment, user_id: user.id, story_id: story.id, created_at: 1.day.ago)
      visit "/s/#{story.short_id}"
      expect(page).not_to have_link('disown')

      page.driver.post "/comments/#{comment.short_id}/disown"
      comment.reload
      expect(comment.user).to eq(user)
    end

    feature "Merging story comments" do
      scenario "upvote merged story comments" do
        comment = create(:comment, user_id: user.id, story_id: story.id, created_at: 90.days.ago)

        stub_login_as user1
        visit "/s/#{story.short_id}"
        expect(page.find(:css, ".comment .comment_text")).to have_content('comment text 5')
        expect(comment.upvotes).to eq(1)
        page.driver.post "/comments/#{comment.short_id}/upvote"
        comment.reload
        expect(comment.upvotes).to eq(2)

        story1.update(merged_stories: [story])
        visit "/s/#{story1.short_id}"
        expect(page.find(:css, ".comment.upvoted .score")).to have_content('2')
      end
    end
  end
end
