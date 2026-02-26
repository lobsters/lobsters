# typed: false

require "rails_helper"

describe UsersHelper do
  describe "#styled_user_link" do
    let(:viewing_user) { create(:user) }
    let(:unrelated_user) { create(:user) }
    let(:new_invited_user) {
      create(:user, created_at: 1.days.ago,
        invited_by_user: viewing_user)
    }
    let(:old_invited_user) {
      create(:user, created_at: (User::MENTORSHIP_DAYS + 1).days.ago,
        invited_by_user: viewing_user)
    }
    let(:new_unrelated_user) { create(:user, created_at: 1.days.ago) }

    it "shows the user name as a link for normal users" do
      assign(:user, viewing_user)

      expect(helper.styled_user_link(unrelated_user)).to eq(link_to(unrelated_user.username,
        user_path(unrelated_user)))
    end

    it "shows the default link for invited users after the interval" do
      assign(:user, viewing_user)

      expect(helper.styled_user_link(old_invited_user)).to eq(link_to(old_invited_user.username,
        user_path(old_invited_user)))
    end

    it "shows invited indication for new, invited user" do
      assign(:user, viewing_user)

      expect(helper.styled_user_link(new_invited_user)).to(
        eq(safe_join([link_to(new_invited_user.username, user_path(new_invited_user),
          {class: "new_user",
           aria: {label: "#{new_invited_user.username} - New user"}}),
          tag.span(class: "you_invited") { "(you invited)" }],
          " "))
      )
    end

    it "shows 'new user' class and aria-label for new, unrelated user" do
      assign(:user, viewing_user)

      expect(helper.styled_user_link(new_unrelated_user)).to(
        eq(link_to(new_unrelated_user.username, user_path(new_unrelated_user),
          {class: "new_user",
           aria: {label: "#{new_unrelated_user.username} - New user"}}))
      )
    end
  end
end
