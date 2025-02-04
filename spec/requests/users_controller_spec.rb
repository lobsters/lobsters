# typed: false

require "rails_helper"

describe "users controller" do
  describe "show user" do
    it "displays the username" do
      user = create(:user)

      get "/~#{user.username}"

      expect(response.body).to include(user.username)
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
