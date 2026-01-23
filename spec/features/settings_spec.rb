# typed: false

require "rails_helper"

RSpec.feature "Settings" do
  let!(:inactive_user) { create(:user, :inactive) }
  let(:user) { create(:user) }

  before(:each) { stub_login_as user }

  scenario "deactivating and reactivating" do
    # true for deactivate; false after
    allow_any_instance_of(User).to receive(:authenticate).with("pass").and_return(true, false)

    page.driver.post "/settings/deactivate", user: {
      i_am_sure: 1, password: "pass", disown: nil
    }
    refute user.reload.is_active?
    expect(Moderation.last.action).to eq("deactivated")

    page.driver.post "/login/reset_password", email: user.email

    page.driver.post "/login/set_new_password", {
      password_reset_token: user.reload.password_reset_token,
      password: "new",
      password_confirmation: "new"
    }
    expect(user.reload.is_active?)
    expect(Moderation.last.action).to eq("reactivated")
  end

  feature "deleting account" do
    scenario "and disowning" do
      story = create :story, user: user
      comment = create :comment, user: user
      allow_any_instance_of(User).to receive(:authenticate).with("pass").and_return(true)

      page.driver.post "/settings/deactivate", user: {
        i_am_sure: 1, password: "pass", disown: 1
      }

      expect(story.reload.user).to eq(inactive_user)
      expect(comment.reload.user).to eq(inactive_user)
      expect(user.stories_submitted_count).to eq(0)
      expect(user.comments_posted_count).to eq(0)
    end

    scenario "uncertain" do
      story = create :story, user: user
      comment = create :comment, user: user
      allow_any_instance_of(User).to receive(:authenticate).with("pass").and_return(true)

      page.driver.post "/settings/deactivate", user: {
        i_am_sure: 0, password: "pass", disown: 0
      }

      expect(user.reload.deleted_at).to be_nil
      expect(story.reload.user).to_not eq(inactive_user)
      expect(comment.reload.user).to_not eq(inactive_user)
    end

    scenario "certain without disown" do
      story = create :story, user: user
      comment = create :comment, user: user
      allow_any_instance_of(User).to receive(:authenticate).with("pass").and_return(true)

      page.driver.post "/settings/deactivate", user: {
        i_am_sure: 1, password: "pass", disown: 0
      }

      expect(user.reload.deleted_at).to_not be_nil
      expect(story.reload.user).to_not eq(inactive_user)
      expect(comment.reload.user).to_not eq(inactive_user)
      expect(user.stories_submitted_count).to_not eq(0)
      expect(user.comments_posted_count).to_not eq(0)
    end
  end
end
