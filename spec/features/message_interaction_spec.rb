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

    visit root_path
    click_on "1 Message"

    expect(current_path).to eq(conversations_path)
    expect(page).to have_css(".conversation.unread", text: "seafood")

    click_on "seafood"

    expect(page).to have_css(".message_text", text: "testing one two three")
  end

  scenario "start a new conversation" do
    user = create(:user)
    stub_login_as user
    other_user = create(:user, username: "seafood")

    visit root_path
    click_on "Messages"
    within(".new_conversation") do
      fill_in "To", with: other_user.username
      fill_in "Subject", with: "Ahoy!"
      fill_in(
        "Message",
        with: "I was wondering if you'd like to get some chowder sometime."
      )
      click_on "Send Message"
    end

    expect(current_path).to eq(conversations_path)
    expect(page).to have_css(".conversation .subject", text: "Ahoy!")
    expect(page).to have_css(
      ".conversation .partner",
      text: other_user.username
    )
  end

  scenario "marks conversations read when they are viewed" do
    user = create(:user)
    stub_login_as user
    other_user = create(:user, username: "seafood")
    conversation = create(
      :conversation,
      author: user,
      recipient: other_user,
      subject: "hi",
    )
    create(
      :message,
      :unread,
      author: other_user,
      recipient: user,
      body: "Nice to meet you",
      conversation: conversation,
    )

    visit root_path
    click_on "1 Message"

    expect(page).to have_css(".conversation.unread .subject", text: "hi")

    click_on other_user.username
    visit conversations_path

    expect(page).not_to have_css(".conversation.unread .subject", text: "hi")
    expect(page).to have_css(".conversation .subject", text: "hi")
    expect(page).not_to have_css(".headerlinks .new_messages")
    expect(page).to have_css(".headerlinks", text: "Messages")
  end

  scenario "add a message to a conversation" do
    user = create(:user)
    stub_login_as user
    other_user = create(:user, username: "seafood")
    conversation = create(
      :conversation,
      author: user,
      recipient: other_user,
      subject: "hi",
    )
    create(
      :message,
      :unread,
      author: other_user,
      recipient: user,
      body: "Nice to meet you",
      conversation: conversation,
    )
    message_text = "Do you like lobster bisque?"

    visit root_path
    click_on "1 Message"
    click_on other_user.username
    within(".new_message") do
      fill_in("Message", with: message_text)
      click_on "Send Message"
    end

    expect(page).to have_css(".message_text", text: message_text)
  end
end
