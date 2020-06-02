require 'rails_helper'

describe 'users controller' do
  describe 'show user' do
    it 'displays the username' do
      user = create(:user)

      get "/u/#{user.username}"

      expect(response.body).to include("User #{user.username}")
    end
  end

  describe 'user standing' do
    let!(:bad_user) { create(:user) }

    before do
      dc = double('DownvotedCommenters')
      bad_user_stats = {
        n_downvotes: 15,
      }
      allow(dc).to receive(:commenters).and_return({
        bad_user.id => bad_user_stats,
      })
      allow(dc).to receive(:check_list_for).and_return(bad_user_stats)
      allow(DownvotedCommenters).to receive(:new).and_return(dc)
    end

    it "displays to the user" do
      sign_in bad_user

      get "/u/#{bad_user.username}/standing"
      expect(response.body).to include("flags")
      expect(response.body).to include("You")
    end

    it "doesn't display to other users" do
      user2 = create(:user)
      sign_in user2

      get "/u/#{bad_user.username}/standing"
      expect(response.status).to eq(302)
    end

    it "doesn't display to logged-out users" do
      get "/u/#{bad_user.username}/standing"
      expect(response.status).to eq(302)
    end

    it "does display to mods" do
      mod = create(:user, :moderator)
      sign_in mod

      get "/u/#{bad_user.username}/standing"
      expect(response.body).to include("flags")
    end
  end
end
