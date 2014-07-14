Given(/^I am logged in$/) do
  @current_user = User.make! email: 'my@mail.com', password: 'mypassword', password_confirmation: 'mypassword'

  visit login_path
  fill_in 'email', with: 'my@mail.com'
  fill_in 'password', with: 'mypassword'
  click_button 'Login'
end
