require 'spec_helper'

feature 'Hiding comments from blocked users' do
  background do
    Tag.create(:tag => "test")
    @user_1 = User.create(username: 'user_1', email: 'user@mail.com', password: '1234567', password_confirmation: '1234567')
    @user_2 = User.create(username: 'user_2', email: 'user2@mail.com', password: '1234567', password_confirmation: '1234567')
    # Add stories for users to comment on
    @user_1.stories.create(title: 'Example story', url: 'http://example.com', tags_a: ['test'])

    # Add comment from user 2
    @user_1.stories.first.comments.create(user: @user_2, comment: 'Leaving a comment')

    # Block user 2
    @user_1.privately_block(@user_2)
  end

  context 'a user views a comment thread' do
    scenario 'it hides comments from blocked users' do
      visit '/login'
      fill_in 'email', with: 'user@mail.com'
      fill_in 'password', with: '1234567'

      find('[name="commit"]').click

      expect(page).to have_content('Example story')
      expect(page).to have_content('1 comment')
      click_on('1 comment')

      expect(page).to have_content('user_2')
      expect(page).to have_content('[Comment hidden because you have this user on your blocked list]')
    end
  end
end
