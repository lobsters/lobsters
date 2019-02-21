require "rails_helper"

RSpec.feature "Checking messages" do
  scenario "see that there are unread messages and read them" do
    user = create(:user)
    stub_login_as user
    other_user = create(:user, username: "seafood")
    conversation = create(:conversation, author: other_user, recipient: user)
    message = create(
      :message,
      body: "testing one two three",
      conversation: conversation,
      author: other_user,
      recipient: user
    )

    visit "/"
    click_on "1 Message"

    expect(current_path).to eq(conversations_path)
    expect(page).to have_css(".conversation.unread", text: "seafood")

    click_on "seafood"

    expect(page).to have_css(".message_text", text: "testing one two three")
  end
end
