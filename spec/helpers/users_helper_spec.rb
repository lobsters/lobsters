# typed: false

require "rails_helper"

describe UsersHelper do
  describe "#styled_user_link" do
    let(:viewing_user) { create(:user) }
    let(:unrelated_user) { create(:user) }
    let(:new_unrelated_user) { create(:user, created_at: 1.days.ago) }

    it "shows the user name as a link for normal users" do
      assign(:user, viewing_user)

      expect(helper.styled_user_link(unrelated_user)).to eq(link_to(unrelated_user.username,
        user_path(unrelated_user)))
    end

    it "shows 'new user' class and aria-label for new, unrelated user" do
      expect(helper.styled_user_link(new_unrelated_user)).to(
        eq(link_to(new_unrelated_user.username, user_path(new_unrelated_user),
          {class: "new_user",
           aria: {label: "#{new_unrelated_user.username} - New user"}}))
      )
    end
  end

  describe "you_invited" do
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

    it "shows invited indication for new, invited user" do
      expect(helper.you_invited(you: viewing_user, user: new_invited_user))
        .to(eq(tag.span(class: "you_invited") { "(you invited)" }))
    end

    it "does not show for new users you didn't invite" do
      expect(helper.you_invited(you: viewing_user, user: new_unrelated_user)).to eq(nil)
    end

    it "does not show for users you invited a while ago" do
      expect(helper.you_invited(you: viewing_user, user: old_invited_user)).to eq(nil)
    end
  end
end
