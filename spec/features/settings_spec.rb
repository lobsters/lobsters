require 'rails_helper'

RSpec.feature "Settings" do
  let!(:inactive_user) { create(:user, :inactive) }
  let(:user) { create(:user) }

  before(:each) { stub_login_as user }

  feature "deleting account" do
    scenario 'and disowning' do
      story = create :story, user: user
      comment = create :comment, user: user
      allow_any_instance_of(User).to receive(:authenticate).with('pass').and_return(true)

      page.driver.post '/settings/delete_account', user: {
        i_am_sure: true, password: 'pass', disown: true,
      }

      expect(story.reload.user).to eq(inactive_user)
      expect(comment.reload.user).to eq(inactive_user)
      expect(user.stories_submitted_count).to eq(0)
      expect(user.comments_posted_count).to eq(0)
    end
  end
end
