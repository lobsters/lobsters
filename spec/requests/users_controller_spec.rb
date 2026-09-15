# typed: false

require "rails_helper"

describe "users controller" do
  describe "show user" do
    it "displays the username" do
      user = create(:user)

      get "/~#{user.username}"

      expect(response.body).to include(user.username)
    end

    it "never shows emails to visitors" do
      user = create(:user, email: "waifu@gmail.com")
      get "/~#{user.username}"
      expect(response.body).to_not include("waifu")

      user.show_email = true
      user.save!

      get "/~#{user.username}"
      # unchanged
      expect(response.body).to_not include("waifu")
    end

    it "allows users to show emails to users" do
      user = create(:user, email: "waifu@gmail.com")

      sign_in create(:user)
      get "/~#{user.username}"
      expect(response.body).to_not include("waifu")

      user.show_email = true
      user.save!

      get "/~#{user.username}"
      expect(response.body).to include("waifu")
    end

    context "when moderator viewing" do
      before { sign_in create(:user, :moderator) }

      it "Displays Activity Log" do
        user = create(:user)

        mod_mail = create(:mod_mail, recipients: [user])

        get "/~#{user.username}"

        expect(response.body).to include(mod_mail.subject)
      end
    end
  end

  describe "tree" do
    let!(:user) { create(:user, username: "alice") }
    let!(:mod) { create(:user, :moderator, username: "bob") }

    it "displays all users" do
      get "/users"
      expect(response.body).to include("alice")
      expect(response.body).to include("bob")
    end

    it "lists mods" do
      get "/users?moderators=1"
      expect(response.body).to_not include("alice")
      expect(response.body).to include("bob")
    end
  end

  describe "user standing" do
    let!(:bad_user) { create(:user) }

    before do
      fc = double("FlaggedCommenters")
      bad_user_stats = {
        n_flags: 15
      }
      allow(fc).to receive(:commenters).and_return({
        bad_user.id => bad_user_stats
      })
      allow(fc).to receive(:check_list_for).and_return(bad_user_stats)
      allow(fc).to receive(:period).and_return(1.month.ago)
      allow(FlaggedCommenters).to receive(:new).and_return(fc)
    end

    it "displays to the user" do
      sign_in bad_user

      get "/~#{bad_user.username}/standing"
      expect(response.body).to include("flags")
      expect(response.body).to include("You")
    end

    it "doesn't display to other users" do
      user2 = create(:user)
      sign_in user2

      get "/~#{bad_user.username}/standing"
      expect(response.status).to eq(302)
    end

    it "doesn't display to logged-out users" do
      get "/~#{bad_user.username}/standing"
      expect(response.status).to eq(302)
    end

    it "does display to mods" do
      mod = create(:user, :moderator)
      sign_in mod

      get "/~#{bad_user.username}/standing"
      expect(response.body).to include("flags")
    end

    it "lists flagged comments from the interval but not before it" do
      flagger = create(:user)
      recent = create(:comment, user: bad_user, comment: "zorkmid recently flagged")
      old = create(:comment, user: bad_user, comment: "zorkmid flagged long ago",
        created_at: 2.months.ago)
      unflagged = create(:comment, user: bad_user, comment: "zorkmid blameless")
      [recent, old].each do |c|
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, c.story_id, c.id, flagger.id, "M")
      end

      sign_in bad_user

      get "/~#{bad_user.username}/standing"
      expect(response.body).to include(recent.comment)
      expect(response.body).to_not include(old.comment)
      expect(response.body).to_not include(unflagged.comment)
    end
  end

  describe "username case mismatch" do
    it "redirects to correct-case user page" do
      user = create(:user)

      get user_path(user.username.upcase)

      expect(response).to redirect_to(user_path(user.username))
    end

    it "redirects to correct-case user standing page" do
      user = create(:user)

      get user_standing_path(user.username.upcase)

      expect(response).to redirect_to(user_standing_path(user.username))
    end
  end
end
