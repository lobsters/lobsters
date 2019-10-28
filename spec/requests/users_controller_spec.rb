require 'rails_helper'

describe 'users controller' do
  describe 'show user' do
    it 'displays the username' do
      user = create(:user)

      get "/u/#{user.username}"

      expect(response.body).to include("User #{user.username}")
    end
  end
end
