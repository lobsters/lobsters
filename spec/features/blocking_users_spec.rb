require 'spec_helper'

feature 'Blocking users' do
  background do
    @user_1 = User.create(username: 'user_1', email: 'user@mail.com', password: '1234567', password_confirmation: '1234567')
    @user_2 = User.create(username: 'user_2', email: 'user2@mail.com', password: '1234567', password_confirmation: '1234567')
  end

  context 'a user tries to block another user' do
    scenario 'it adds a user to the block list' do
      visit '/login'
      fill_in 'email', with: 'user@mail.com'
      fill_in 'password', with: '1234567'

      find('[name="commit"]').click

      expect(page).to have_content('user_1')
      expect(page).to have_content('Logout')

      visit '/u/user_2'
      expect(page).to have_content('user_2')

      find('.block-user').click
      expect(page).to have_content('User has been blocked')
    end
  end
end
