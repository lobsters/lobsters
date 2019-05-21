require "rails_helper"

RSpec.feature "Checking messages" do
  scenario "see that there are unread messages" do
    user = create(:user)
    stub_login_as user
    other_user = create(:user, username: "seafood")
    conversation = create(:conversation, author: other_user, recipient: user)
    message = create(
      :message,
      conversation: conversation,
      author: other_user,
      recipient: user
    )

    visit "/"
    click_on "1 Message"

    expect(current_path).to eq(conversations_path)
    expect(page).to have_css(".conversation.unread", text: "seafood")
  end
end
